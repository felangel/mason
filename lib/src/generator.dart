import 'dart:convert';
import 'dart:io' show Directory, File, Process, ProcessException, ProcessResult;

import 'package:checked_yaml/checked_yaml.dart';
import 'package:path/path.dart' as p;
import 'package:mason/src/mason_configuration.dart';

import 'manifest.dart';
import 'render.dart';

/// {@template generator}
/// An abstract class which both defines a template generator and can generate a
/// user project based on this template.
/// {@endtemplate}
abstract class Generator implements Comparable<Generator> {
  /// {@macro generator}
  Generator(
    this.id,
    this.description,
  );

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
  Future generate(
    GeneratorTarget target, {
    Map<String, String> vars,
  }) {
    return Future.forEach(files, (TemplateFile file) {
      final resultFile = file.runSubstitution(vars ?? <String, String>{});
      final filePath = resultFile.path;
      return target.createFile(filePath, resultFile.content);
    });
  }

  @override
  int compareTo(Generator other) =>
      id.toLowerCase().compareTo(other.id.toLowerCase());

  @override
  String toString() => '[$id: $description]';
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
/// variables that can be substituted (`__myVar__`).
/// {@endtemplate}
class TemplateFile {
  /// {@macro template_file}
  TemplateFile(this.path, this.content);

  /// The template file path.
  final String path;

  /// The template file content.
  final String content;

  /// Performs a substitution on the [path] based on the incoming [parameters].
  FileContents runSubstitution(Map<String, String> parameters) {
    final newPath = path.render(parameters);
    final newContents = _createContent(parameters);

    return FileContents(newPath, newContents);
  }

  List<int> _createContent(Map<String, String> vars) {
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

/// A [MasonGenerator] which extends [Generator] and
/// exposes the ability to create a [Generator] from a
/// `yaml` file.
class MasonGenerator extends Generator {
  MasonGenerator._(
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
  /// a configuration file:
  ///
  /// ```yaml
  /// name: greetings
  /// description: A Simple Greetings Template
  /// files:
  ///   - from: greetings.md
  ///     to: GREETINGS.md
  /// vars:
  ///   - name
  /// ```
  static Future<MasonGenerator> fromTemplate(
    MasonTemplate template, {
    String workingDirectory = '',
  }) async {
    File templateYamlFile;
    String templateYamlContent;

    if (template.path != null) {
      templateYamlFile = File(p.join(workingDirectory, template.path));
      templateYamlContent = await templateYamlFile.readAsString();
    } else if (template.git != null) {
      final tempDirectory = await _createSystemTempDir();
      await _runGit(['clone', template.git.url, tempDirectory]);
      if (template.git.ref != null) {
        await _runGit(
          ['checkout', template.git.ref],
          processWorkingDir: tempDirectory,
        );
      }
      templateYamlFile = File(
        p.join(workingDirectory, tempDirectory, template.git.path ?? ''),
      );
      templateYamlContent = await templateYamlFile.readAsString();
    } else {
      throw const FormatException('missing template source');
    }

    final manifest = checkedYamlDecode(
      templateYamlContent,
      (m) => Manifest.fromJson(m),
    );
    final parentDirectory = templateYamlFile.parent;
    final templateDirectory = Directory(
      p.join(parentDirectory.path, manifest.template),
    );
    final futures = templateDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) {
      return () async {
        final content = await File(file.path).readAsString();
        final relativePath = file.path.substring(
          file.path.indexOf(manifest.template) + 1 + manifest.template.length,
        );
        return TemplateFile(relativePath, content);
      }();
    });
    return MasonGenerator._(
      manifest.name,
      manifest.description,
      files: await Future.wait(futures),
      vars: manifest.vars,
    );
  }

  /// Optional list of variables which will be used to populate
  /// the corresponding mustache variables within the template.
  final List<String> vars;
}

Future<ProcessResult> _runGit(List<String> args,
    {bool throwOnError = true, String processWorkingDir}) async {
  final pr = await Process.run('git', args,
      workingDirectory: processWorkingDir, runInShell: true);

  if (throwOnError) {
    _throwIfProcessFailed(pr, 'git', args);
  }
  return pr;
}

void _throwIfProcessFailed(
    ProcessResult pr, String process, List<String> args) {
  assert(pr != null);
  if (pr.exitCode != 0) {
    final values = {
      'Standard out': pr.stdout.toString().trim(),
      'Standard error': pr.stderr.toString().trim()
    }..removeWhere((k, v) => v.isEmpty);

    String message;
    if (values.isEmpty) {
      message = 'Unknown error';
    } else if (values.length == 1) {
      message = values.values.single;
    } else {
      message = values.entries.map((e) => '${e.key}\n${e.value}').join('\n');
    }

    throw ProcessException(process, args, message, pr.exitCode);
  }
}

Future<String> _createSystemTempDir() async {
  var tempDir = await Directory.systemTemp.createTemp('mason_');
  return tempDir.resolveSymbolicLinksSync();
}
