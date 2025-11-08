import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

/// {@template make_command}
/// `mason make` command which generates code based on a brick template.
/// {@endtemplate}
class MakeCommand extends MasonCommand {
  /// {@macro make_command}
  MakeCommand({Logger? logger, ProcessSignal? sigint}) : super(logger: logger) {
    argParser.addOptions();
    try {
      for (final brick in bricks) {
        addSubcommand(
          _MakeCommand(
            brick,
            sigint: sigint ?? ProcessSignal.sigint,
            logger: logger,
          ),
        );
      }
    } catch (e) {
      _exception = e;
    }
  }

  Object? _exception;

  @override
  final String description = 'Generate code using an existing brick template.';

  @override
  final String name = 'make';

  @override
  Future<int> run() async {
    // ignore: only_throw_errors
    if (_exception != null) throw _exception!;
    final subcommand = results.rest.isNotEmpty ? results.rest.first : '';
    usageException(
      '''Could not find a subcommand named "$subcommand" for "mason make".''',
    );
  }
}

class _MakeCommand extends MasonCommand {
  _MakeCommand(this._brick, {required ProcessSignal sigint, super.logger})
      : _sigint = sigint {
    argParser
      ..addOptions()
      ..addSeparator('${'-' * 79}\n');

    for (final entry in _brick.vars.entries) {
      final variable = entry.key;
      final properties = entry.value;
      argParser.addOption(
        variable,
        help: properties.toHelp(),
      );
    }
  }

  final BrickYaml _brick;
  final ProcessSignal _sigint;

  @override
  String get description => _brick.description;

  @override
  String get name => _brick.name;

  @override
  Future<int> run() async {
    if (!isBrickCompatibleWithMason(_brick)) {
      logger.err(
        '''The current mason version is $packageVersion.\nBecause $name requires mason version ${_brick.environment.mason}, version solving failed.''',
      );

      return ExitCode.software.code;
    }

    final outputDir = canonicalize(
      p.join(cwd.path, results['output-dir'] as String),
    );
    final configPath = results['config-path'] as String?;
    final fileConflictResolution =
        (results['on-conflict'] as String).toFileConflictResolution();
    final setExitIfChanged = results['set-exit-if-changed'] as bool;
    final target = DirectoryGeneratorTarget(Directory(outputDir));
    final disableHooks = results['no-hooks'] as bool;
    final quietMode = results['quiet'] as bool;
    final watch = results['watch'] as bool;

    Future<int> _make() async {
      final path = File(_brick.path!).parent.path;
      final generator = await MasonGenerator.fromBrick(Brick.path(path));
      final vars = <String, dynamic>{};

      try {
        vars.addAll(await _decodeFile(configPath));
      } on FormatException catch (error) {
        logger.err('${error}in $configPath');
        return ExitCode.usage.code;
      } catch (error) {
        logger.err('$error');
        return ExitCode.usage.code;
      }

      for (final entry in _brick.vars.entries) {
        final variable = entry.key;
        final properties = entry.value;
        if (vars.containsKey(variable)) continue;
        final arg = results[variable] as String?;
        if (arg != null) {
          vars.addAll(<String, dynamic>{variable: _maybeDecode(arg)});
        } else {
          final prompt =
              '''${styleBold.wrap(lightGreen.wrap('?'))} ${properties.prompt ?? variable}''';
          late final dynamic response;
          switch (properties.type) {
            case BrickVariableType.string:
              response = _maybeDecode(
                logger.prompt(prompt, defaultValue: properties.defaultValue),
              );
            case BrickVariableType.number:
              response = logger.prompt(
                prompt,
                defaultValue: properties.defaultValue,
              );
              if (num.tryParse(response as String) == null) {
                throw FormatException(
                  'Invalid $variable.\n"$response" is not a number.',
                );
              }
            case BrickVariableType.boolean:
              response = logger.confirm(
                prompt,
                defaultValue: properties.defaultValue as bool? ?? false,
              );
            case BrickVariableType.enumeration:
              final choices = properties.values;
              if (choices == null || choices.isEmpty) {
                throw FormatException(
                  'Invalid $variable.\n"Enums must have at least one value.',
                );
              }
              response = logger.chooseOne(
                prompt,
                choices: choices,
                defaultValue: properties.defaultValue?.toString(),
              );
            case BrickVariableType.array:
              final choices = properties.values;
              if (choices == null || choices.isEmpty) {
                throw FormatException(
                  'Invalid $variable.\n"Arrays must have at least one value.',
                );
              }
              response = logger.chooseAny(
                prompt,
                choices: choices,
                defaultValues:
                    (properties.defaultValues as List?)?.cast<String>(),
              );
            case BrickVariableType.list:
              response = logger.promptAny(
                prompt,
                separator: properties.separator ?? ',',
              );
          }
          vars.addAll(<String, dynamic>{variable: response});
        }
      }

      Map<String, dynamic>? updatedVars;

      if (!disableHooks) {
        await generator.hooks.preGen(
          vars: vars,
          workingDirectory: outputDir,
          onVarsChanged: (vars) => updatedVars = vars,
          logger: logger,
        );
      }

      final generateProgress = logger.progress('Making ${generator.id}');
      try {
        final files = await generator.generate(
          target,
          vars: updatedVars ?? vars,
          fileConflictResolution: fileConflictResolution,
          logger: logger,
        );
        generateProgress.complete(
          'Generated ${files.length} ${files.length == 1 ? 'file' : 'files'}.',
        );

        if (!quietMode) {
          logger.flush((message) => logger.info(darkGray.wrap(message)));
        }

        if (!disableHooks) {
          await generator.hooks.postGen(
            vars: updatedVars ?? vars,
            workingDirectory: outputDir,
            logger: logger,
          );
        }

        if (setExitIfChanged) {
          final filesChanged = files.where((file) => file.hasChanged);
          logger.logFilesChanged(filesChanged.length);
          if (filesChanged.isNotEmpty) return ExitCode.software.code;
        }

        return ExitCode.success.code;
      } catch (_) {
        generateProgress.fail();
        rethrow;
      }
    }

    if (!watch) return _make();

    await _make();

    final brickDirectoryPath = p.dirname(_brick.path!);
    final watcher = DirectoryWatcher(brickDirectoryPath);
    final watchSubscription = watcher.events.listen(
      (event) {
        if (event.type == ChangeType.REMOVE) {
          File(
            p.join(
              outputDir,
              p.relative(
                event.path,
                from: p.join(brickDirectoryPath, BrickYaml.dir),
              ),
            ),
          ).deleteSync(recursive: true);
        }
        _make();
      },
    );

    final signal = await _sigint.watch().first;
    await watchSubscription.cancel();
    return signal.signalNumber;
  }

  Future<Map<String, dynamic>> _decodeFile(String? path) async {
    if (path == null) return <String, dynamic>{};
    final content = await File(path).readAsString();
    return json.decode(content) as Map<String, dynamic>;
  }

  dynamic _maybeDecode(String value) {
    try {
      return json.decode(value);
    } catch (_) {
      return value;
    }
  }
}

extension on GeneratedFile {
  bool get hasChanged {
    switch (status) {
      case GeneratedFileStatus.created:
      case GeneratedFileStatus.overwritten:
      case GeneratedFileStatus.appended:
        return true;
      case GeneratedFileStatus.skipped:
      case GeneratedFileStatus.identical:
        return false;
    }
  }
}

extension on BrickVariableType {
  String get name {
    switch (this) {
      case BrickVariableType.array:
        return 'array';
      case BrickVariableType.number:
        return 'number';
      case BrickVariableType.string:
        return 'string';
      case BrickVariableType.boolean:
        return 'boolean';
      case BrickVariableType.enumeration:
        return 'enum';
      case BrickVariableType.list:
        return 'list';
    }
  }
}

extension on BrickVariableProperties {
  String toHelp() {
    final _type = '<${type.name}>';
    final _defaultValue =
        type == BrickVariableType.string ? '"$defaultValue"' : '$defaultValue';
    final _values = values as List?;
    return [
      [
        if (description != null) description,
        _type,
      ].join(' '),
      if (defaultValue != null) '(defaults to $_defaultValue)',
      if (_values != null) '[${_values.cast<String>().join(', ')}]',
    ].join('\n');
  }
}

extension on ArgParser {
  void addOptions() {
    addFlag(
      'quiet',
      abbr: 'q',
      help: 'Run with reduced verbosity.',
      negatable: false,
    );
    addFlag('no-hooks', help: 'Skips running hooks.', negatable: false);
    addFlag(
      'set-exit-if-changed',
      help: 'Return exit code 70 if there are files modified.',
      negatable: false,
    );
    addFlag(
      'watch',
      help: 'Watch the ${BrickYaml.dir} directory for changes.',
      negatable: false,
    );
    addOption(
      'config-path',
      abbr: 'c',
      help: 'Path to config json file containing variables.',
    );
    addOption(
      'output-dir',
      abbr: 'o',
      help: 'Directory where to output the generated code.',
      defaultsTo: '.',
    );
    addOption(
      'on-conflict',
      allowed: ['prompt', 'overwrite', 'append', 'skip'],
      defaultsTo: 'prompt',
      allowedHelp: {
        'prompt': 'Always prompt the user for each file conflict.',
        'overwrite': 'Always overwrite conflicting files.',
        'append': 'Always append conflicting files.',
        'skip': 'Always skip conflicting files.',
      },
      help: 'File conflict resolution strategy.',
    );
  }
}

extension on String {
  FileConflictResolution toFileConflictResolution() {
    switch (this) {
      case 'skip':
        return FileConflictResolution.skip;
      case 'overwrite':
        return FileConflictResolution.overwrite;
      case 'append':
        return FileConflictResolution.append;
      default:
        return FileConflictResolution.prompt;
    }
  }
}

extension on Logger {
  void logFilesChanged(int fileCount) {
    if (fileCount == 0) return info('${lightGreen.wrap('✓')} 0 files changed');
    return fileCount == 1
        ? err('${lightRed.wrap('✗')} $fileCount file changed')
        : err('${lightRed.wrap('✗')} $fileCount files changed');
  }
}
