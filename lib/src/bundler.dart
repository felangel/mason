import 'dart:convert';
import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:path/path.dart' as path;

import 'brick_yaml.dart';
import 'mason_bundle.dart';

final _binaryFileTypes = RegExp(
  r'\.(jpe?g|png|gif|ico|svg|ttf|eot|woff|woff2|otf)$',
  caseSensitive: false,
);

/// Generates a [MasonBundle] from the provided [brick] directory.
Future<MasonBundle> createBundle(Directory brick) async {
  final brickYamlFile = File(path.join(brick.path, BrickYaml.file));
  final brickYaml = checkedYamlDecode(
    brickYamlFile.readAsStringSync(),
    (m) => BrickYaml.fromJson(m!),
  );
  final files = Directory(path.join(brick.path, BrickYaml.dir))
      .listSync(recursive: true)
      .whereType<File>()
      .map(_bundleFile)
      .toList();
  return MasonBundle(
    brickYaml.name,
    brickYaml.description,
    brickYaml.vars,
    files,
  );
}

MasonBundledFile _bundleFile(File file) {
  final fileType =
      _binaryFileTypes.hasMatch(path.basename(file.path)) ? 'binary' : 'text';
  final data = base64.encode(file.readAsBytesSync());
  final filePath = path.joinAll(
    path.split(file.path).skipWhile((value) => value != BrickYaml.dir).skip(1),
  );
  return MasonBundledFile(filePath, data, fileType);
}
