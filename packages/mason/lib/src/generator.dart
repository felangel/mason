import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:mason/mason.dart';
import 'package:mason/src/mason_bundle.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart' show Directory, File, FileMode, Process;

part 'generator_target.dart';
part 'hooks.dart';
part 'mason_generator.dart';

final _partialRegExp = RegExp(r'\{\{~\s(.+)\s\}\}');
final _fileRegExp = RegExp(r'{{%\s?([a-zA-Z]+)\s?%}}');
final _delimeterRegExp = RegExp('{{(.*?)}}');
final _loopKeyRegExp = RegExp('{{#(.*?)}}');
final _loopValueReplaceRegExp = RegExp('({{{.*?}}})');
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
    FileConflictResolution? fileConflictResolution,
    Logger? logger,
  }) async {
    final overwriteRule = fileConflictResolution?.toOverwriteRule();
    var fileCount = 0;
    await Future.forEach<TemplateFile>(files, (TemplateFile file) async {
      final fileMatch = _fileRegExp.firstMatch(file.path);
      if (fileMatch != null) {
        final resultFile = await _fetch(vars[fileMatch[1]] as String);
        if (resultFile.path.isEmpty) return;
        await target.createFile(
          p.basename(resultFile.path),
          resultFile.content,
          logger: logger,
          overwriteRule: overwriteRule,
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
          await target.createFile(
            file.path,
            file.content,
            logger: logger,
            overwriteRule: overwriteRule,
          );
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
    try {
      final decoded = utf8.decode(content);
      if (!decoded.contains(_delimeterRegExp)) return content;
      final rendered = decoded.render(vars, partials);
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
