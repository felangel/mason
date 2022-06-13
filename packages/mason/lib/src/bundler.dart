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

/// Generates a [MasonBundle] from the provided [brickPath] directory.
MasonBundle createBundle(String brickPath) {
  if (!Directory(brickPath).existsSync()) {
    throw BrickNotFoundException(brickPath);
  }
  final brickYamlFile = File(path.join(brickPath, BrickYaml.file));
  if (!brickYamlFile.existsSync()) {
    throw BrickNotFoundException(brickYamlFile.path);
  }
  final brickYaml = checkedYamlDecode(
    brickYamlFile.readAsStringSync(),
    (m) => BrickYaml.fromJson(m!),
  );
  final files = Directory(path.join(brickPath, BrickYaml.dir))
      .listSync(recursive: true)
      .whereType<File>()
      .map(_bundleBrickFile)
      .toList();
  final hooksDirectory = Directory(path.join(brickPath, BrickYaml.hooks));
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
    repository: brickYaml.repository,
    files: files..sort(_comparePaths),
    hooks: hooks..sort(_comparePaths),
    readme: _bundleTopLevelFile(brickPath, 'README.md'),
    changelog: _bundleTopLevelFile(brickPath, 'CHANGELOG.md'),
    license: _bundleTopLevelFile(brickPath, 'LICENSE'),
  );
}

int _comparePaths(MasonBundledFile a, MasonBundledFile b) {
  return a.path.toLowerCase().compareTo(b.path.toLowerCase());
}

MasonBundledFile? _bundleTopLevelFile(String brickPath, String fileName) {
  final file = File(path.join(brickPath, fileName));
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
