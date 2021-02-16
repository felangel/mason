import 'dart:convert';
import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:mason/src/brick_yaml.dart';
import 'package:path/path.dart' as path;

import 'mason_bundle.dart';

final RegExp _binaryFileTypes = RegExp(
    r'\.(jpe?g|png|gif|ico|svg|ttf|eot|woff|woff2)$',
    caseSensitive: false);

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
