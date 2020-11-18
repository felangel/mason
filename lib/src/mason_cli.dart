import 'dart:convert';
import 'dart:io' as io;
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

import 'generator.dart';
import 'logger.dart';
import 'options.dart';
import 'version.dart';

/// {@template mason_cli}
/// Mason CLI which helps you lay the foundation for your next project!
/// {@endtemplate}
class MasonCli {
  /// {@macro mason_cli}
  MasonCli(this.logger);

  /// [Logger] instance used to output information.
  final Logger logger;

  io.Directory _cwd;

  /// Return the current working directory.
  io.Directory get cwd => _cwd ?? io.Directory.current;

  /// An override for the directory to generate into; public for testing.
  set cwd(io.Directory value) => _cwd = value;

  /// Builds template based on supplied [options].
  Future<void> build(Options options, List<String> args) async {
    final dir = cwd;
    final target = _DirectoryGeneratorTarget(logger, dir);

    if (options.template == null) {
      logger
        ..err('Specify a template')
        ..info('')
        ..info(usage);
      io.exitCode = ExitCode.usage.code;
      return;
    }

    final stop = logger.progress('building');
    try {
      final generator = await MasonGenerator.fromYaml(options.template);
      final vars = <String, String>{};

      for (final variable in generator.vars) {
        final index = args.indexOf('--$variable');
        if (index != -1) {
          vars.addAll({variable: args[index + 1]});
        }
      }

      await generator.generate(target, vars: vars);
      stop();
      logger.success('built [${generator.id}] in ${target.dir.path}');
    } on Exception catch (e) {
      stop();
      logger.err(e.toString());
    }
  }

  /// Outputs information about CLI usage.
  void help() {
    logger
      ..alert('⛏️  mason \u{2022} lay the foundation!')
      ..info(usage);
  }

  /// Outputs CLI version information.
  void version() {
    logger.info('mason version: $packageVersion');
  }

  /// Outputs an error along with CLI Usage information.
  void unrecognized() {
    logger
      ..err("Specify a command: ${parser.commands.keys.join(', ')}")
      ..info('')
      ..info(usage);
    io.exitCode = ExitCode.usage.code;
  }

  /// Returns CLI Usage information.
  static String get usage {
    return '''
Usage: mason <command> [<args>]
${styleBold.wrap('Commands:')}
  build   build new component from a template
${styleBold.wrap('Arguments:')}
${_indent(parser.usage)}''';
  }
}

String _indent(String input) =>
    LineSplitter.split(input).map((l) => '  $l'.trimRight()).join('\n');

class _DirectoryGeneratorTarget extends GeneratorTarget {
  _DirectoryGeneratorTarget(this.logger, this.dir) {
    dir.createSync();
  }

  final Logger logger;
  final io.Directory dir;

  @override
  Future<io.File> createFile(String filePath, List<int> contents) {
    final file = io.File(path.join(dir.path, filePath));

    return file
        .create(recursive: true)
        .then<io.File>((_) => file.writeAsBytes(contents));
  }
}
