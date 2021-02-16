import 'dart:convert';
import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:mason/src/brick_yaml.dart';
import 'package:path/path.dart' as path;

final RegExp _binaryFileTypes = RegExp(
    r'\.(jpe?g|png|gif|ico|svg|ttf|eot|woff|woff2)$',
    caseSensitive: false);

/// {@template mason_bundled_file}
/// A bundled file which is included as part of a a [MasonBundle].
/// {@endtemplate}
class MasonBundledFile {
  /// {@macro mason_bundled_file}
  const MasonBundledFile(this.path, this.data, this.type);

  /// The relative file path
  final String path;

  /// The encoded contents of the file
  final String data;

  /// The type of file (binary/text)
  final String type;

  /// Converts a json string into a [MasonBundledFile].
  static MasonBundledFile fromJson(String data) {
    final decoded = json.decode(data) as Map;
    return MasonBundledFile(
      decoded['path'] as String,
      decoded['data'] as String,
      decoded['type'] as String,
    );
  }

  /// Converts a [MasonBundledFile] into a json string.
  String toJson() {
    return json.encode({
      'path': path,
      'data': data,
      'type': type,
    });
  }
}

/// {@template mason_bundle}
/// A bundled version of a mason template.
/// {@endtemplate}
class MasonBundle {
  /// {@macro mason_bundle}
  const MasonBundle(
    this.name,
    this.description,
    this.vars,
    this.files,
  );

  /// List of all [MasonBundledFile] instances for the particular brick.
  final List<MasonBundledFile> files;

  /// Name of the brick (from the `brick.yaml`).
  final String name;

  /// Description of the brick (from the `brick.yaml`).
  final String description;

  /// All required variables for the brick (from the `brick.yaml`).
  final List<String> vars;

  /// Converts a [Map<String, dynamic>] into a [MasonBundle] instance.
  static MasonBundle fromJson(Map<String, dynamic> json) {
    return MasonBundle(
      json['name'] as String,
      json['description'] as String,
      (json['vars'] as List).map((dynamic v) => v.toString()).toList(),
      (json['files'] as List)
          .map((dynamic f) => MasonBundledFile.fromJson(f as String))
          .toList(),
    );
  }

  /// Converts a [MasonBundle] into a json string.
  String toJson() {
    return json.encode({
      'name': name,
      'description': description,
      'files': files.map((f) => f.toJson()).toList(),
      'vars': vars,
    });
  }
}

/// Generates a [MasonBundle] from the provided [brick] directory.
Future<MasonBundle> convertBrickToBundle(Directory brick) async {
  final bundledFiles = <MasonBundledFile>[];
  final brickYamlFile = File(path.join(brick.path, BrickYaml.file));
  final brickYaml = checkedYamlDecode(
    brickYamlFile.readAsStringSync(),
    (m) => BrickYaml.fromJson(m),
  );
  final files = Directory(path.join(brick.path, BrickYaml.dir))
      .listSync(recursive: true)
      .whereType<File>();
  for (final file in files) {
    final filePath = path.split(file.path).skip(3).join('/');
    final data = base64.encode(file.readAsBytesSync());
    final fileType =
        _binaryFileTypes.hasMatch(path.basename(file.path)) ? 'binary' : 'text';
    bundledFiles.add(MasonBundledFile(filePath, data, fileType));
  }
  return MasonBundle(
    brickYaml.name,
    brickYaml.description,
    brickYaml.vars,
    bundledFiles,
  );
}
