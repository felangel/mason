import 'dart:async';
import 'dart:convert';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:mason/mason.dart';
import 'package:mason/src/mason_bundle.dart';
import 'package:mason/src/render.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart' show Directory, File, FileMode, Process;

final _partialRegExp = RegExp(r'\{\{~\s(.+)\s\}\}');
final _fileRegExp = RegExp(r'{{%\s?([a-zA-Z]+)\s?%}}');
final _delimeterRegExp = RegExp('{{(.*?)}}');
final _loopKeyRegExp = RegExp('{{#(.*?)}}');
final _loopValueReplaceRegExp = RegExp('({{{.*?}}})');
final _newlineOutRegExp = RegExp(r'(\r\n|\r|\n)');
final _newlineInRegExp = RegExp(r'(\\\r\n|\\\r|\\\n)');
final _unicodeOutRegExp = RegExp(r'[^\x00-\x7F]');
final _unicodeInRegExp = RegExp(r'\\[^\x00-\x7F]');
final _whiteSpace = RegExp(r'\s+');
final _lambdas = RegExp(
  '''(camelCase|constantCase|dotCase|headerCase|lowerCase|pascalCase|paramCase|pathCase|sentenceCase|snakeCase|titleCase|upperCase)''',
);

RegExp _loopRegExp([String name = '.*?']) {
  return RegExp('({{#$name}}.*?{{{.*?}}}.*?{{/$name}})');
}

RegExp _loopValueRegExp([String name = '.*?']) {
  return RegExp('{{#$name}}.*?{{{(.*?)}}}.*?{{/$name}}');
}

RegExp _loopInnerRegExp([String name = '.*?']) {
  return RegExp('{{#$name}}(.*?{{{.*?}}}.*?){{/$name}}');
}

/// {@template mason_generator}
/// A [MasonGenerator] which extends [Generator] and
/// exposes the ability to create a [Generator] from a
/// [Brick].
/// {@endtemplate}
class MasonGenerator extends Generator {
  /// {@macro mason_generator}
  MasonGenerator(
    String id,
    String description, {
    List<TemplateFile?> files = const <TemplateFile>[],
    GeneratorHooks hooks = const GeneratorHooks(),
    this.vars = const <String>[],
  }) : super(id, description, hooks) {
    for (final file in files) {
      addTemplateFile(file);
    }
  }

  /// Factory which creates a [MasonGenerator] based on
  /// a configuration file for a [BrickYaml]:
  ///
  /// ```yaml
  /// name: greetings
  /// description: A Simple Greetings Template
  /// vars:
  ///   - name
  /// ```
  static Future<MasonGenerator> fromBrickYaml(BrickYaml brick) async {
    final brickRoot = File(brick.path!).parent.path;
    final brickDirectory = p.join(brickRoot, BrickYaml.dir);
    final brickFiles = Directory(brickDirectory)
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) {
      return () async {
        try {
          final content = await File(file.path).readAsBytes();
          final relativePath = file.path.substring(
            file.path.indexOf(BrickYaml.dir) + 1 + BrickYaml.dir.length,
          );
          return TemplateFile.fromBytes(relativePath, content);
        } on Exception {
          return null;
        }
      }();
    });

    return MasonGenerator(
      brick.name,
      brick.description,
      vars: brick.vars,
      files: await Future.wait(brickFiles),
      hooks: await GeneratorHooks.fromBrickYaml(brick),
    );
  }

  /// Factory which creates a [MasonGenerator] based on
  /// a local [MasonBundle].
  static Future<MasonGenerator> fromBundle(MasonBundle bundle) async {
    return MasonGenerator(
      bundle.name,
      bundle.description,
      vars: bundle.vars,
      files: _decodeConcatenatedData(bundle.files),
      hooks: GeneratorHooks.fromBundle(bundle),
    );
  }

  /// Factory which creates a [MasonGenerator] based on
  /// a [GitPath] for a remote [BrickYaml] file.
  static Future<MasonGenerator> fromGitPath(GitPath gitPath) async {
    final directory = await BricksJson.temp().add(Brick(git: gitPath));
    final file = File(p.join(directory, gitPath.path, BrickYaml.file));
    final brickYaml = checkedYamlDecode(
      file.readAsStringSync(),
      (m) => BrickYaml.fromJson(m!),
    ).copyWith(path: file.path);
    return MasonGenerator.fromBrickYaml(brickYaml);
  }

  /// Optional list of variables which will be used to populate
  /// the corresponding mustache variables within the template.
  final List<String> vars;
}

/// Supported types of [GeneratorHooks].
enum GeneratorHook {
  /// Script run immediately before the `generate` method is invoked.
  preGen,

  /// Script run immediately after the `generate` method is invoked.
  postGen,
}

extension on GeneratorHook {
  String toFileName() {
    switch (this) {
      case GeneratorHook.preGen:
        return 'pre_gen.dart';
      case GeneratorHook.postGen:
        return 'post_gen.dart';
    }
  }
}

/// {@template generator_hooks}
/// Scripts that run automatically whenever a particular event occurs
/// in a [Generator].
/// {@endtemplate}
class GeneratorHooks {
  /// {@macro generator_hooks}
  const GeneratorHooks({this.preGen, this.postGen});

  /// Creates [GeneratorHooks] from a provided [MasonBundle].
  factory GeneratorHooks.fromBundle(MasonBundle bundle) {
    ScriptFile? _decodeHookScript(MasonBundledFile? file) {
      if (file == null) return null;
      final path = file.path;
      final raw = file.data.replaceAll(_whiteSpace, '');
      final decoded = base64.decode(raw);
      try {
        return ScriptFile.fromBytes(path, decoded);
      } catch (_) {
        return null;
      }
    }

    final preGen = bundle.hooks.firstWhereOrNull(
      (element) {
        return p.basename(element.path) == GeneratorHook.preGen.toFileName();
      },
    );
    final postGen = bundle.hooks.firstWhereOrNull(
      (element) {
        return p.basename(element.path) == GeneratorHook.postGen.toFileName();
      },
    );

    return GeneratorHooks(
      preGen: _decodeHookScript(preGen),
      postGen: _decodeHookScript(postGen),
    );
  }

  /// Creates [GeneratorHooks] from a provided [BrickYaml].
  static Future<GeneratorHooks> fromBrickYaml(BrickYaml brick) async {
    Future<ScriptFile?> getHookScript(GeneratorHook hook) async {
      try {
        final brickRoot = File(brick.path!).parent.path;
        final hooksDirectory = Directory(p.join(brickRoot, BrickYaml.hooks));
        final file =
            hooksDirectory.listSync().whereType<File>().firstWhereOrNull(
                  (element) => p.basename(element.path) == hook.toFileName(),
                );

        if (file == null) return null;
        final content = await file.readAsBytes();
        final relativePath = file.path.substring(
          file.path.indexOf(BrickYaml.dir) + 1 + BrickYaml.dir.length,
        );
        return ScriptFile.fromBytes(relativePath, content);
      } catch (_) {
        return null;
      }
    }

    return GeneratorHooks(
      preGen: await getHookScript(GeneratorHook.preGen),
      postGen: await getHookScript(GeneratorHook.postGen),
    );
  }

  /// Script run immediately before the `generate` method is invoked.
  final ScriptFile? preGen;

  /// Script run immediately after the `generate` method is invoked.
  final ScriptFile? postGen;
}

/// {@template generator}
/// An abstract class which both defines a template generator and can generate a
/// user project based on this template.
/// {@endtemplate}
abstract class Generator implements Comparable<Generator> {
  /// {@macro generator}
  Generator(this.id, this.description, [this.hooks = const GeneratorHooks()]);

  /// Unique identifier for the generator.
  final String id;

  /// Description of the generator.
  final String description;

  /// Hooks associated with the generator.
  final GeneratorHooks hooks;

  /// List of [TemplateFile] which will be used to generate files.
  final List<TemplateFile> files = [];

  /// Map of partial files which will be used as includes.
  ///
  /// Contains a Map of partial file path to partial file content.
  final Map<String, List<int>> partials = {};

  /// Add a new template file.
  void addTemplateFile(TemplateFile? file) {
    if (file == null) return;
    _partialRegExp.hasMatch(file.path)
        ? partials.addAll({file.path: file.content})
        : files.add(file);
  }

  /// Generates files based on the provided [GeneratorTarget] and [vars].
  Future<int> generate(
    GeneratorTarget target, {
    Map<String, dynamic> vars = const <String, dynamic>{},
  }) async {
    var fileCount = 0;
    await Future.forEach<TemplateFile>(files, (TemplateFile file) async {
      final fileMatch = _fileRegExp.firstMatch(file.path);
      if (fileMatch != null) {
        final resultFile = await _fetch(vars[fileMatch[1]] as String);
        if (resultFile.path.isEmpty) return;
        await target.createFile(
          p.basename(resultFile.path),
          resultFile.content,
        );
        fileCount++;
      } else {
        final resultFiles = file.runSubstitution(
          Map<String, dynamic>.of(vars),
          Map<String, List<int>>.of(partials),
        );
        final root = RegExp(r'\w:\\|\w:\/');
        final separator = RegExp(r'\/|\\');
        final rootOrSeparator = RegExp('$root|$separator');
        final wasRoot = file.path.startsWith(rootOrSeparator);
        for (final file in resultFiles) {
          final isRoot = file.path.startsWith(rootOrSeparator);
          if (!wasRoot && isRoot) continue;
          if (file.path.isEmpty) continue;
          if (file.path.split(separator).contains('')) continue;
          await target.createFile(file.path, file.content);
          fileCount++;
        }
      }
    });
    return fileCount;
  }

  @override
  int compareTo(Generator other) =>
      id.toLowerCase().compareTo(other.id.toLowerCase());

  @override
  String toString() => '[$id: $description]';

  Future<FileContents> _fetch(String path) async {
    final file = File(path);
    final isLocal = file.existsSync();
    if (isLocal) {
      final target = p.join(Directory.current.path, p.basename(file.path));
      final bytes = await file.readAsBytes();
      return FileContents(target, bytes);
    } else {
      final uri = Uri.parse(path);
      final target = p.join(Directory.current.path, p.basename(uri.path));
      final response = await http.Client().get(uri);
      return FileContents(target, response.bodyBytes);
    }
  }
}

/// File conflict resolution strategies used during
/// the generation process.
enum FileConflictResolution {
  /// Always prompt the user for each file conflict.
  prompt,

  /// Always overwrite conflicting files.
  overwrite,

  /// Always skip conflicting files.
  skip,

  /// Always append conflicting files.
  append,
}

/// The overwrite rule when generating code and a conflict occurs.
enum OverwriteRule {
  /// Always overwrite the existing file.
  alwaysOverwrite,

  /// Always skip overwriting the existing file.
  alwaysSkip,

  /// Always append the existing file.
  alwaysAppend,

  /// Overwrite one time.
  overwriteOnce,

  /// Do not overwrite one time.
  skipOnce,

  /// Append one time
  appendOnce,
}

/// {@template directory_generator_target}
/// A [GeneratorTarget] based on a provided [Directory].
/// {@endtemplate}
class DirectoryGeneratorTarget extends GeneratorTarget {
  /// {@macro directory_generator_target}
  DirectoryGeneratorTarget(
    this.dir, [
    this.logger,
    FileConflictResolution? fileConflictResolution,
  ]) : _overwriteRule = fileConflictResolution?.toOverwriteRule() {
    dir.createSync(recursive: true);
  }

  /// The target [Directory].
  final Directory dir;

  /// Optional logger used to output created files.
  final Logger? logger;

  /// The rule used to handle file conflicts.
  /// Determines whether to overwrite existing file or skip.
  OverwriteRule? _overwriteRule;

  @override
  Future<File> createFile(String path, List<int> contents) async {
    final file = File(p.join(dir.path, path));
    final fileExists = file.existsSync();

    if (fileExists) {
      final existingContents = file.readAsBytesSync();

      if (const ListEquality<int>().equals(existingContents, contents)) {
        logger?.delayed('  ${file.path} ${lightCyan.wrap('(identical)')}');
        return file;
      }

      final shouldPrompt = logger != null &&
          (_overwriteRule != OverwriteRule.alwaysOverwrite &&
              _overwriteRule != OverwriteRule.alwaysSkip &&
              _overwriteRule != OverwriteRule.alwaysAppend);

      if (shouldPrompt) {
        logger?.info('${red.wrap(styleBold.wrap('conflict'))} ${file.path}');
        _overwriteRule = logger
            ?.prompt(
              yellow.wrap(
                styleBold.wrap('Overwrite ${p.basename(file.path)}? (Yyna) '),
              ),
            )
            .toOverwriteRule();
      }
    }

    switch (_overwriteRule) {
      case OverwriteRule.alwaysSkip:
      case OverwriteRule.skipOnce:
        logger?.delayed('  ${file.path} ${yellow.wrap('(skip)')}');
        return file;
      case OverwriteRule.alwaysOverwrite:
      case OverwriteRule.overwriteOnce:
      case OverwriteRule.appendOnce:
      case OverwriteRule.alwaysAppend:
      case null:
        final shouldAppend = _overwriteRule == OverwriteRule.appendOnce ||
            _overwriteRule == OverwriteRule.alwaysAppend;
        return file
            .create(recursive: true)
            .then<File>(
              (_) => file.writeAsBytes(
                contents,
                mode: shouldAppend ? FileMode.append : FileMode.write,
              ),
            )
            .whenComplete(
              () => shouldAppend
                  ? logger?.delayed(
                      '  ${file.path} ${lightBlue.wrap('(modified)')}',
                    )
                  : logger?.delayed(
                      '  ${file.path} ${lightGreen.wrap('(new)')}',
                    ),
            );
    }
  }
}

/// A target for a [Generator].
/// This class knows how to create files given a path and contents.
// ignore: one_member_abstracts
abstract class GeneratorTarget {
  /// Create a file at the given path with the given contents.
  Future createFile(String path, List<int> contents);
}

/// {@template script_file}
/// This class represents a script file in a generator.
/// The contents should be text and may contain mustache.
/// {@endtemplate}
class ScriptFile {
  /// {@macro script_file}
  ScriptFile.fromBytes(this.path, this.content);

  /// The template file path.
  final String path;

  /// The template file content.
  final List<int> content;

  /// Performs a substitution on the [path] based on the incoming [parameters].
  FileContents runSubstitution(Map<String, dynamic> parameters) {
    return FileContents(path, _createContent(parameters));
  }

  List<int> _createContent(Map<String, dynamic> vars) {
    String sanitizeInput(String input) {
      return input.replaceAllMapped(
        RegExp('${_newlineOutRegExp.pattern}|${_unicodeOutRegExp.pattern}'),
        (match) => match.group(0) != null ? '\\${match.group(0)}' : match.input,
      );
    }

    String sanitizeOutput(String output) {
      return output.replaceAllMapped(
        RegExp('${_newlineInRegExp.pattern}|${_unicodeInRegExp.pattern}'),
        (match) => match.group(0)?.substring(1) ?? match.input,
      );
    }

    try {
      final decoded = utf8.decode(content);
      if (!decoded.contains(_delimeterRegExp)) return content;
      final sanitized = sanitizeInput(decoded);
      final rendered = sanitizeOutput(sanitized.render(vars));
      return utf8.encode(rendered);
    } on Exception {
      return content;
    }
  }

  /// Executes the current script with the provided [vars] and [logger].
  /// An optional [workingDirectory] can also be specified.
  Future<int> run({
    Map<String, dynamic> vars = const <String, dynamic>{},
    Logger? logger,
    String? workingDirectory,
  }) async {
    final tempDir = Directory.systemTemp.createTempSync();
    final script = File(p.join(tempDir.path, p.basename(path)))
      ..writeAsBytesSync(runSubstitution(vars).content);
    final result = await Process.run(
      'dart',
      [script.path],
      workingDirectory: workingDirectory,
    );

    final stdout = result.stdout as String?;
    if (stdout != null && stdout.isNotEmpty) logger?.info(stdout.trim());

    final stderr = result.stderr as String?;
    if (stderr != null && stderr.isNotEmpty) logger?.err(stderr.trim());

    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}

    return result.exitCode;
  }
}

/// {@template template_file}
/// This class represents a file in a generator template.
/// The contents should be text and may contain mustache
/// variables that can be substituted (`{{myVar}}`).
/// {@endtemplate}
class TemplateFile {
  /// {@macro template_file}
  TemplateFile(String path, String content)
      : this.fromBytes(path, utf8.encode(content));

  /// {@macro template_file}
  TemplateFile.fromBytes(this.path, this.content);

  /// The template file path.
  final String path;

  /// The template file content.
  final List<int> content;

  /// Performs a substitution on the [path] based on the incoming [parameters].
  Set<FileContents> runSubstitution(
    Map<String, dynamic> parameters,
    Map<String, List<int>> partials,
  ) {
    var filePath = path.replaceAll(r'\', '/');
    if (_loopRegExp().hasMatch(filePath)) {
      final matches = _loopKeyRegExp.allMatches(filePath);

      for (final match in matches) {
        final key = match.group(1);
        if (key == null || _lambdas.hasMatch(key)) continue;
        final value = _loopValueRegExp(key).firstMatch(filePath)![1];
        final inner = _loopInnerRegExp(key).firstMatch(filePath)![1];
        final target = inner!.replaceFirst(
          _loopValueReplaceRegExp,
          '{{$key.$value}}',
        );
        filePath = filePath.replaceFirst(_loopRegExp(key), target);
      }

      final fileContents = <FileContents>{};
      final parameterKeys =
          parameters.keys.where((key) => parameters[key] is List).toList();
      final permutations = _Permutations<dynamic>(
        [
          ...parameters.entries
              .where((entry) => entry.value is List)
              .map((entry) => entry.value as List)
        ],
      ).generate();
      for (final permutation in permutations) {
        final param = Map<String, dynamic>.of(parameters);
        for (var i = 0; i < permutation.length; i++) {
          param.addAll(<String, dynamic>{parameterKeys[i]: permutation[i]});
        }
        final newPath = filePath.render(param);
        final newContents = TemplateFile(
          newPath,
          utf8.decode(content),
        )._createContent(parameters..addAll(param), partials);
        fileContents.add(FileContents(newPath, newContents));
      }

      return fileContents;
    } else {
      final newPath = filePath.render(parameters);
      final newContents = _createContent(parameters, partials);
      return {FileContents(newPath, newContents)};
    }
  }

  List<int> _createContent(
    Map<String, dynamic> vars,
    Map<String, List<int>> partials,
  ) {
    String sanitizeInput(String input) {
      return input.replaceAllMapped(
        RegExp('${_newlineOutRegExp.pattern}|${_unicodeOutRegExp.pattern}'),
        (match) => match.group(0) != null ? '\\${match.group(0)}' : match.input,
      );
    }

    String sanitizeOutput(String output) {
      return output.replaceAllMapped(
        RegExp('${_newlineInRegExp.pattern}|${_unicodeInRegExp.pattern}'),
        (match) => match.group(0)?.substring(1) ?? match.input,
      );
    }

    try {
      final decoded = utf8.decode(content);
      if (!decoded.contains(_delimeterRegExp)) return content;
      final rendered = sanitizeOutput(
        sanitizeInput(decoded).render(vars, (name) {
          return partialResolver(name, partials, sanitizeInput);
        }),
      );
      return utf8.encode(rendered);
    } on Exception {
      return content;
    }
  }
}

/// {@template file_contents}
/// A representation of the contents for a specific file.
/// {@endtemplate}
@immutable
class FileContents {
  /// {@macro file_contents}
  const FileContents(this.path, this.content);

  /// The file path.
  final String path;

  /// The contents of the file.
  final List<int> content;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is FileContents &&
        other.path == path &&
        listEquals(other.content, content);
  }

  @override
  int get hashCode => path.hashCode ^ content.length.hashCode;
}

class _Permutations<T> {
  _Permutations(this.elements);
  final List<List<T>> elements;

  List<List<T>> generate() {
    final perms = <List<T>>[];
    _generatePermutations(elements, perms, 0, []);
    return perms;
  }

  void _generatePermutations(
    List<List<T>> lists,
    List<List<T>> result,
    int depth,
    List<T> current,
  ) {
    if (depth == lists.length) {
      result.add(current);
      return;
    }

    for (var i = 0; i < lists[depth].length; i++) {
      _generatePermutations(
        lists,
        result,
        depth + 1,
        [...current, lists[depth][i]],
      );
    }
  }
}

List<TemplateFile> _decodeConcatenatedData(List<MasonBundledFile> files) {
  final results = <TemplateFile>[];
  for (final file in files) {
    final path = file.path;
    final type = file.type;
    final raw = file.data.replaceAll(_whiteSpace, '');
    final decoded = base64.decode(raw);
    try {
      if (type == 'binary') {
        results.add(TemplateFile.fromBytes(path, decoded));
      } else {
        final source = utf8.decode(decoded);
        results.add(TemplateFile(path, source));
      }
    } catch (_) {}
  }

  return results;
}

extension on FileConflictResolution {
  OverwriteRule? toOverwriteRule() {
    switch (this) {
      case FileConflictResolution.overwrite:
        return OverwriteRule.alwaysOverwrite;
      case FileConflictResolution.skip:
        return OverwriteRule.alwaysSkip;
      case FileConflictResolution.append:
        return OverwriteRule.alwaysAppend;
      case FileConflictResolution.prompt:
        return null;
    }
  }
}

extension on String {
  OverwriteRule toOverwriteRule() {
    switch (this) {
      case 'n':
        return OverwriteRule.skipOnce;
      case 'a':
        return OverwriteRule.appendOnce;
      case 'Y':
        return OverwriteRule.alwaysOverwrite;
      case 'y':
      default:
        return OverwriteRule.overwriteOnce;
    }
  }
}
