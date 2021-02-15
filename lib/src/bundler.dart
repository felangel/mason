import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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

class MasonBundle {
  const MasonBundle(
    this.name,
    this.description,
    this.vars,
    this.files,
  );
  final List<MasonBundledFile> files;
  final String description;
  final String name;
  final List<String> vars;

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

  String toJson() {
    return json.encode({
      'name': name,
      'description': description,
      'files': files.map((f) => f.toJson()).toList(),
      'vars': vars,
    });
  }
}

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
    final data = _base64encode(file.readAsBytesSync());
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

String _base64encode(List<int> bytes) {
  final encoded = base64.encode(bytes);

  /// Split lines into 80-character chunks
  /// to make the source code more readable.
  final lines = <String>[];
  var index = 0;

  while (index < encoded.length) {
    final line = encoded.substring(index, math.min(index + 80, encoded.length));
    lines.add(line);
    index += line.length;
  }

  return lines.join('\r\n');
}
