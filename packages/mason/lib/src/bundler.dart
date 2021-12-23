import 'dart:convert';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/mason_bundle.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';

final _binaryFileTypes = RegExp(
  r'\.(jpe?g|png|gif|ico|svg|ttf|eot|woff|woff2|otf)$',
  caseSensitive: false,
);

/// Generates a [MasonBundle] from the provided [brick] directory.
MasonBundle createBundle(Directory brick) {
  final brickYamlFile = File(path.join(brick.path, BrickYaml.file));
  if (!brickYamlFile.existsSync()) {
    throw BrickNotFoundException(brickYamlFile.path);
  }
  final brickYaml = checkedYamlDecode(
    brickYamlFile.readAsStringSync(),
    (m) => BrickYaml.fromJson(m!),
  );
  final files = Directory(path.join(brick.path, BrickYaml.dir))
      .listSync(recursive: true)
      .whereType<File>()
      .map(_bundleBrickFile)
      .toList();
  final hooksDirectory = Directory(path.join(brick.path, BrickYaml.hooks));
  final hooks = hooksDirectory.existsSync()
      ? hooksDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .map(_bundleHookFile)
          .toList()
      : <MasonBundledFile>[];
  return MasonBundle(
    brickYaml.name,
    brickYaml.description,
    brickYaml.vars,
    files,
    hooks,
  );
}

MasonBundledFile _bundleBrickFile(File file) {
  final fileType =
      _binaryFileTypes.hasMatch(path.basename(file.path)) ? 'binary' : 'text';
  final data = base64.encode(file.readAsBytesSync());
  final filePath = path.joinAll(
    path.split(file.path).skipWhile((value) => value != BrickYaml.dir).skip(1),
  );
  return MasonBundledFile(filePath, data, fileType);
}

MasonBundledFile _bundleHookFile(File file) {
  final data = base64.encode(file.readAsBytesSync());
  final filePath = path.basename(file.path);
  return MasonBundledFile(filePath, data, 'text');
}
