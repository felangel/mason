import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'brick_yaml.dart';
import 'logger.dart';
import 'mason_cache.dart';
import 'mason_yaml.dart';
import 'render.dart';

final _fileRegExp = RegExp(r'<%\s?([a-zA-Z]+)\s?%>');

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
    List<TemplateFile> files,
    this.vars = const <String>[],
  }) : super(id, description) {
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
  static Future<MasonGenerator> fromBrickYaml(
    BrickYaml brick,
    MasonCache cache,
    String directory,
  ) async {
    final futures = Directory(directory)
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) {
      return () async {
        final content = await File(file.path).readAsString();
        final relativePath = file.path.substring(
          file.path.indexOf(BrickYaml.dir) + 1 + BrickYaml.dir.length,
        );
        return TemplateFile(relativePath, content);
      }();
    });
    return MasonGenerator(
      brick.name,
      brick.description,
      files: await Future.wait(futures),
      vars: brick.vars,
    );
  }

  /// Optional list of variables which will be used to populate
  /// the corresponding mustache variables within the template.
  final List<String> vars;
}

/// {@template generator}
/// An abstract class which both defines a template generator and can generate a
/// user project based on this template.
/// {@endtemplate}
abstract class Generator implements Comparable<Generator> {
  /// {@macro generator}
  Generator(this.id, this.description);

  /// Unique identifier for the generator.
  final String id;

  /// Description of the generator.
  final String description;

  /// List of [TemplateFile] which will be used to generate files.
  final List<TemplateFile> files = [];

  /// Add a new template file.
  TemplateFile addTemplateFile(TemplateFile file) {
    files.add(file);
    return file;
  }

  /// Generates files based on the provided [GeneratorTarget] and [vars].
  Future<void> generate(
    GeneratorTarget target, {
    Map<String, dynamic> vars,
  }) async {
    await Future.forEach(files, (TemplateFile file) async {
      final fileMatch = _fileRegExp.firstMatch(file.path);
      if (fileMatch != null) {
        final resultFile = await _fetch(vars[fileMatch[1]] as String);
        return target.createFile(resultFile.path, resultFile.content);
      }

      final resultFile = file.runSubstitution(vars ?? <String, dynamic>{});
      return target.createFile(resultFile.path, resultFile.content);
    });
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

/// {@template directory_generator_target}
/// A [GeneratorTarget] based on a provided [Directory].
/// {@endtemplate}
class DirectoryGeneratorTarget extends GeneratorTarget {
  /// {@macro directory_generator_target}
  DirectoryGeneratorTarget(this.dir, this.logger) {
    dir.createSync();
  }

  /// The target [Directory].
  final Directory dir;

  /// Logger used to output created files.
  final Logger logger;

  @override
  Future<File> createFile(String path, List<int> contents) {
    final file = File(p.join(dir.path, path));

    return file
        .create(recursive: true)
        .then<File>((_) => file.writeAsBytes(contents))
        .whenComplete(() => logger.delayed('  ${file.path} (new)'));
  }
}

/// A target for a [Generator].
/// This class knows how to create files given a path and contents.
abstract class GeneratorTarget {
  /// Create a file at the given path with the given contents.
  Future createFile(String path, List<int> contents);
}

/// {@template template_file}
/// This class represents a file in a generator template.
/// The contents should be text and may contain mustache
/// variables that can be substituted (`{{myVar}}`).
/// {@endtemplate}
class TemplateFile {
  /// {@macro template_file}
  TemplateFile(this.path, this.content);

  /// The template file path.
  final String path;

  /// The template file content.
  final String content;

  /// Performs a substitution on the [path] based on the incoming [parameters].
  FileContents runSubstitution(Map<String, dynamic> parameters) {
    final newPath = path.render(parameters);
    final newContents = _createContent(parameters);

    return FileContents(newPath, newContents);
  }

  List<int> _createContent(Map<String, dynamic> vars) {
    return utf8.encode(content.render(vars));
  }
}

/// {@template file_contents}
/// A representation of the contents for a specific file.
/// {@endtemplate}
class FileContents {
  /// {@macro file_contents}
  const FileContents(this.path, this.content);

  /// The file path.
  final String path;

  /// The contents of the file.
  final List<int> content;
}
