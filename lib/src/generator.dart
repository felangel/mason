// ignore_for_file: public_member_api_docs
import 'dart:convert';

import 'common.dart';

/// {@template generator}
/// An abstract class which both defines a template generator and can generate a
/// user project based on this template.
/// {@endtemplate}
abstract class Generator implements Comparable<Generator> {
  /// {@macro generator}
  Generator(
    this.id,
    this.label,
    this.description, {
    this.categories = const [],
  });

  final String id;
  final String label;
  final String description;
  final List<String> categories;

  final List<TemplateFile> files = [];
  TemplateFile _entrypoint;

  /// The entrypoint of the application; the main file for the project, which an
  /// IDE might open after creating the project.
  TemplateFile get entrypoint => _entrypoint;

  /// Add a new template file.
  TemplateFile addTemplateFile(TemplateFile file) {
    files.add(file);
    return file;
  }

  /// Return the template file wih the given [path].
  TemplateFile getFile(String path) {
    return files.firstWhere((file) => file.path == path, orElse: () => null);
  }

  /// Set the main entrypoint of this template.
  /// This is the 'most important' file of this template.
  /// An IDE might use this information to open this file
  /// after the user's project is generated.
  void setEntrypoint(TemplateFile entrypoint) {
    if (_entrypoint != null) throw StateError('entrypoint already set');
    if (entrypoint == null) throw StateError('entrypoint is null');
    _entrypoint = entrypoint;
  }

  Future generate(
    String projectName,
    GeneratorTarget target, {
    Map<String, String> additionalVars,
  }) {
    final vars = {
      'projectName': projectName,
      'description': description,
      'year': DateTime.now().year.toString(),
      'author': '<your name>'
    };

    if (additionalVars != null) {
      for (final key in additionalVars.keys) {
        vars[key] = additionalVars[key];
      }
    }

    return Future.forEach(files, (TemplateFile file) {
      var resultFile = file.runSubstitution(vars);
      var filePath = resultFile.path;
      return target.createFile(filePath, resultFile.content);
    });
  }

  /// Return the number of files.
  int numFiles() => files.length;

  @override
  int compareTo(Generator other) =>
      id.toLowerCase().compareTo(other.id.toLowerCase());

  /// Return some user facing instructions
  /// about how to finish installation of the template.
  String getInstallInstructions() => '';

  @override
  String toString() => '[$id: $description]';
}

/// A target for a [Generator].
/// This class knows how to create files given a path
/// for the file (relavtive to the particular [GeneratorTarget] instance), and
/// the binary content for the file.
abstract class GeneratorTarget {
  /// Create a file at the given path with the given contents.
  Future createFile(String path, List<int> contents);
}

/// {@template template_file}
/// This class represents a file in a generator template. The contents could
/// either be binary or text. If text, the contents may contain mustache
/// variables that can be substituted (`__myVar__`).
/// {@endtemplate}
class TemplateFile {
  /// {@macro template_file}
  TemplateFile(this.path, this.content);

  /// Creates a [TemplateFile] from binary data.
  TemplateFile.fromBinary(this.path, this._binaryData) : content = null;

  /// The template file path.
  final String path;

  /// The template file content.
  final String content;

  List<int> _binaryData;

  FileContents runSubstitution(Map<String, String> parameters) {
    if (path == 'pubspec.yaml' && parameters['author'] == '<your name>') {
      parameters = Map.from(parameters);
      parameters['author'] = 'Your Name';
    }

    final newPath = substituteVars(path, parameters);
    final newContents = _createContent(parameters);

    return FileContents(newPath, newContents);
  }

  /// Return if TemplateFile consists of binary data.
  bool get isBinary => _binaryData != null;

  List<int> _createContent(Map<String, String> vars) {
    if (isBinary) {
      return _binaryData;
    } else {
      return utf8.encode(substituteVars(content, vars));
    }
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
