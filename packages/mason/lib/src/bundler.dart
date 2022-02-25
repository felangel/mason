import 'dart:convert';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';

final _binaryFileTypes = RegExp(
  r'\.(jpe?g|png|gif|ico|svg|ttf|eot|woff|woff2|otf)$',
  caseSensitive: false,
);

final _hookFiles = RegExp('(pre_gen.dart|post_gen.dart|pubspec.yaml)');

/// Unpack the [bundle] in the [target] directory.
void unpackBundle(MasonBundle bundle, Directory target) {
  for (final file in bundle.files) {
    _unbundleFile(file, path.join(target.path, BrickYaml.dir));
  }
  for (final hook in bundle.hooks) {
    _unbundleFile(hook, path.join(target.path, BrickYaml.hooks));
  }
  final brickYaml = BrickYaml(
    name: bundle.name,
    description: bundle.description,
    version: bundle.version,
    environment: bundle.environment,
    vars: bundle.vars,
  );
  File(path.join(target.path, BrickYaml.file)).writeAsStringSync(
    json.encode(brickYaml.toJson()),
  );
}

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
          .where((file) => _hookFiles.hasMatch(path.basename(file.path)))
          .map(_bundleHookFile)
          .toList()
      : <MasonBundledFile>[];
  return MasonBundle(
    name: brickYaml.name,
    description: brickYaml.description,
    version: brickYaml.version,
    environment: brickYaml.environment,
    vars: brickYaml.vars,
    files: files..sort(_comparePaths),
    hooks: hooks..sort(_comparePaths),
  );
}

int _comparePaths(MasonBundledFile a, MasonBundledFile b) {
  return a.path.toLowerCase().compareTo(b.path.toLowerCase());
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

File _unbundleFile(MasonBundledFile file, String target) {
  final data = base64.decode(file.data);
  final filePath = path.join(target, file.path);
  return File(filePath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data);
}
