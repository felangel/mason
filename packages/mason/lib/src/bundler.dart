import 'dart:convert';
import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

final _binaryFileTypes = RegExp(
  r'\.(jpe?g|png|gif|ico|svg|ttf|eot|woff|woff2|otf|mp3)$',
  caseSensitive: false,
);

final _hookFiles = RegExp(r'^(.*.dart|pubspec.yaml)$');

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
    repository: bundle.repository,
  );
  File(path.join(target.path, BrickYaml.file)).writeAsStringSync(
    Yaml.encode(brickYaml.toJson()),
  );

  final readme = bundle.readme;
  if (readme != null) _unbundleFile(readme, target.path);

  final changelog = bundle.changelog;
  if (changelog != null) _unbundleFile(changelog, target.path);

  final license = bundle.license;
  if (license != null) _unbundleFile(license, target.path);
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
  final brickDir = Directory(path.join(brick.path, BrickYaml.dir));
  final files = brickDir.existsSync()
      ? brickDir
          .listSync(recursive: true)
          .whereType<File>()
          .map(_bundleBrickFile)
          .toList()
      : <MasonBundledFile>[];
  final hooksDirectory = Directory(path.join(brick.path, BrickYaml.hooks));
  final hooks = hooksDirectory.existsSync()
      ? hooksDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => _hookFiles.hasMatch(path.basename(file.path)))
          .map((file) => _bundleHookFile(file, hooksDirectory))
          .toList()
      : <MasonBundledFile>[];
  return MasonBundle(
    name: brickYaml.name,
    description: brickYaml.description,
    version: brickYaml.version,
    environment: brickYaml.environment,
    vars: brickYaml.vars,
    repository: brickYaml.repository,
    files: files..sort(_comparePaths),
    hooks: hooks..sort(_comparePaths),
    readme: _bundleTopLevelFile(brick, 'README.md'),
    changelog: _bundleTopLevelFile(brick, 'CHANGELOG.md'),
    license: _bundleTopLevelFile(brick, 'LICENSE'),
  );
}

int _comparePaths(MasonBundledFile a, MasonBundledFile b) {
  return a.path.toLowerCase().compareTo(b.path.toLowerCase());
}

MasonBundledFile? _bundleTopLevelFile(Directory brick, String fileName) {
  final file = File(path.join(brick.path, fileName));
  if (!file.existsSync()) return null;
  final data = base64.encode(file.readAsBytesSync());
  return MasonBundledFile(path.basename(file.path), data, 'text');
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

MasonBundledFile _bundleHookFile(File file, Directory hooksDirectory) {
  final data = base64.encode(file.readAsBytesSync());
  final filePath = path.relative(file.path, from: hooksDirectory.path);
  return MasonBundledFile(filePath, data, 'text');
}

File _unbundleFile(MasonBundledFile file, String target) {
  final data = base64.decode(file.data);
  final filePath = path.join(target, file.path);
  return File(filePath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data);
}
