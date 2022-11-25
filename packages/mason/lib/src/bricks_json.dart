import 'dart:convert';
import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:http/http.dart' as http;
import 'package:mason/mason.dart';
import 'package:mason/src/git.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// {@template brick_resolve_version_exception}
/// Thrown when an error occurs while resolving a brick version.
/// {@endtemplate}
class BrickResolveVersionException extends MasonException {
  /// {@macro brick_resolve_version_exception}
  const BrickResolveVersionException(String message) : super(message);
}

/// {@template mason_yaml_name_mismatch}
/// Thrown when a brick's name in `mason.yaml` does not match
/// the name in `brick.yaml`.
/// {@endtemplate}
class MasonYamlNameMismatch extends MasonException {
  /// {@macro mason_yaml_name_mismatch}
  MasonYamlNameMismatch(String message) : super(message);
}

/// {@template brick_unsatisfied_version_constraint}
/// Thrown when a brick version constraint could not be satisfied.
/// {@endtemplate}
class BrickUnsatisfiedVersionConstraint extends MasonException {
  /// {@macro brick_unsatisfied_version_constraint}
  BrickUnsatisfiedVersionConstraint(String message) : super(message);
}

/// {@template malformed_bricks_json}
/// Thrown when a brick from mason.yaml cannot be found in bricks.json.
/// {@endtemplate}
class MalformedBricksJson extends MasonException {
  /// {@macro malformed_bricks_json}
  const MalformedBricksJson(String message) : super(message);
}

/// {@template brick_incompatible_mason_version}
/// Thrown when the current mason version is incompatible with the brick.
/// {@endtemplate}
class BrickIncompatibleMasonVersion extends MasonException {
  /// {@macro brick_incompatible_mason_version}
  BrickIncompatibleMasonVersion({
    required String brickName,
    required String constraint,
  }) : super(
          '''The current mason version is $packageVersion.\nBecause $brickName requires mason version $constraint, version solving failed.''',
        );
}

/// {@template cached_brick}
/// A cached brick is an object which includes a resolved
/// [brick] (strict location) and the local path of the brick.
/// {@endtemplate}
class CachedBrick {
  /// {@macro cached_brick}
  const CachedBrick({required this.brick, required this.path});

  /// The resolved brick with a fixed [BrickLocation].
  final Brick brick;

  /// The brick's local path.
  final String path;
}

/// {@template bricks_json}
/// A local cache for mason bricks.
///
/// This cache contains local paths to all bricks.
/// {@endtemplate}
class BricksJson {
  /// Creates a [BricksJson] instance from the [directory].
  BricksJson({required Directory directory}) {
    _bricksJsonFile = File(p.join(directory.path, '.mason', 'bricks.json'));
    if (directory.path == BricksJson.globalDir.path) {
      _bricksJsonFile.createSync(recursive: true);
    }
    _cache = _fromFile(_bricksJsonFile);
  }

  /// Creates a [BricksJson] instance from the global bricks.json file.
  BricksJson.global() : this(directory: BricksJson.globalDir);

  /// Creates a [BricksJson] instance from a temporary directory.
  BricksJson.temp() : this(directory: Directory.systemTemp.createTempSync());

  /// Environment map which can be overridden for testing purposes.
  @visibleForTesting
  static Map<String, String>? testEnvironment;

  /// bool which can be overridden for test purposes
  /// to indicate the platform is windows.
  @visibleForTesting
  static bool? testIsWindows;

  /// Map of Brick to local path for bricks.
  late Map<String, String> _cache;

  /// Associated bricks.json file
  late File _bricksJsonFile;

  /// Read-only cache of brick,location pairs.
  Map<String, String> get cache => _cache;

  /// Removes all key/value pairs from the cache.
  void clear() {
    _cache.clear();
    try {
      _bricksJsonFile.deleteSync();
    } catch (_) {}
  }

  /// Populates cache based on `.mason/bricks.json`.
  Map<String, String> _fromFile(File bricksJson) {
    if (!bricksJson.existsSync()) return <String, String>{};
    final content = bricksJson.readAsStringSync();
    if (content.isEmpty) return <String, String>{};
    try {
      return Map.castFrom<dynamic, dynamic, String, String>(
        json.decode(content) as Map,
      );
    } catch (error) {
      throw MalformedBricksJson(
        'Malformed bricks.json at ${bricksJson.path}\n$error',
      );
    }
  }

  /// Encodes entire cache contents.
  String get encode => json.encode(_cache);

  /// Removes current [brick] from `bricks.json`.
  void remove(Brick brick) => _cache.remove(brick.name);

  /// Flushes cache contents to `bricks.json`.
  Future<void> flush() async {
    await _bricksJsonFile.create(recursive: true);
    await _bricksJsonFile.writeAsString(encode);
  }

  /// Returns the local path to the brick if it is included in the cache.
  /// Returns `null` if the brick has not been cached.
  String? getPath(Brick brick) {
    return brick.name != null ? _cache[brick.name] : null;
  }

  /// Caches brick if necessary and updates `bricks.json`.
  /// Returns the [CachedBrick] which includes the resolved brick
  /// and local path.
  Future<CachedBrick> add(Brick brick) async {
    if (brick.location.path != null) {
      return _addLocalBrick(brick);
    }

    if (brick.location.git != null) {
      return _addRemoteBrickFromGit(brick);
    }

    return _addRemoteBrickFromRegistry(brick);
  }

  /// Writes local brick at using path to cache
  /// and returns the local path to the brick.
  CachedBrick _addLocalBrick(Brick brick) {
    final path = brick.location.path!;
    final brickYaml = File(p.join(path, BrickYaml.file));

    if (!brickYaml.existsSync()) {
      throw BrickNotFoundException(canonicalize(path));
    }

    final yaml = checkedYamlDecode(
      brickYaml.readAsStringSync(),
      (m) => BrickYaml.fromJson(m!),
    );

    final name = brick.name ?? yaml.name;
    if (yaml.name != name) {
      throw MasonYamlNameMismatch(
        'Brick name "$name" '
        'doesn\'t match provided name "${yaml.name}" in ${MasonYaml.file}.',
      );
    }

    _verifyMasonVersionConstraint(yaml);

    final localPath = getPath(brick) ?? canonicalize(brick.location.path!);
    _cache[name] = localPath;
    return CachedBrick(brick: brick, path: localPath);
  }

  /// Writes remote brick via git url to cache
  /// and returns the local path to the brick.
  Future<CachedBrick> _addRemoteBrickFromGit(Brick brick) async {
    final gitPath = brick.location.git!;
    final tempDirectory = await _clone(gitPath);
    final commitHash = await _revParse(tempDirectory);
    final resolvedBrick = Brick.git(
      GitPath(gitPath.url, path: gitPath.path, ref: commitHash),
    );
    final dirName = _encodedGitDir(gitPath, commitHash);

    final directory = Directory(p.join(rootDir.path, 'git', dirName));
    final directoryExists = directory.existsSync();
    final directoryIsNotEmpty =
        directoryExists && directory.listSync(recursive: true).isNotEmpty;

    BrickYaml _getBrickYaml(Directory directory) {
      final gitPath = brick.location.git!;
      final brickYaml = File(
        p.join(directory.path, gitPath.path, BrickYaml.file),
      );

      if (!brickYaml.existsSync()) {
        if (directory.existsSync()) directory.deleteSync(recursive: true);
        final url = gitPath.path.isNotEmpty
            ? '${gitPath.url}/${gitPath.path}'
            : gitPath.url;
        throw BrickNotFoundException(url);
      }

      final yaml = checkedYamlDecode(
        brickYaml.readAsStringSync(),
        (m) => BrickYaml.fromJson(m!),
      );

      return yaml;
    }

    /// Even if a cached version exists, still try to update.
    /// Fall-back to cached version if update fails.
    if (directoryExists && directoryIsNotEmpty) {
      try {
        await directory.delete(recursive: true);
        await directory.parent.create(recursive: true);
        await tempDirectory.rename(directory.path);
      } catch (_) {}

      final yaml = _getBrickYaml(directory);
      final name = brick.name ?? yaml.name;

      if (yaml.name != name) {
        throw MasonYamlNameMismatch(
          'Brick name "$name" '
          'doesn\'t match provided name "${yaml.name}" in ${MasonYaml.file}.',
        );
      }

      _verifyMasonVersionConstraint(yaml);

      final localPath = canonicalize(p.join(directory.path, gitPath.path));
      _cache[name] = localPath;
      return CachedBrick(brick: resolvedBrick, path: localPath);
    }

    if (directoryExists) await directory.delete(recursive: true);

    await directory.parent.create(recursive: true);
    await tempDirectory.rename(directory.path);

    final yaml = _getBrickYaml(directory);
    final name = brick.name ?? yaml.name;

    if (yaml.name != name) {
      throw MasonYamlNameMismatch(
        'Brick name "$name" '
        'doesn\'t match provided name "${yaml.name}" in ${MasonYaml.file}.',
      );
    }

    _verifyMasonVersionConstraint(yaml);

    final localPath = canonicalize(p.join(directory.path, gitPath.path));
    _cache[name] = localPath;
    return CachedBrick(brick: resolvedBrick, path: localPath);
  }

  Future<Directory> _clone(GitPath gitPath) async {
    final directory = Directory.systemTemp.createTempSync();
    await Git.run(['clone', gitPath.url, directory.path]);
    if (gitPath.ref != null) {
      await Git.run(
        ['checkout', gitPath.ref!],
        processWorkingDir: directory.path,
      );
    }
    return directory;
  }

  Future<String> _revParse(Directory directory) async {
    final result = await Git.run(
      ['rev-parse', 'HEAD'],
      processWorkingDir: directory.path,
    );
    return (result.stdout as String).trim();
  }

  /// Writes remote brick from registry to cache
  /// and returns the local path to the brick.
  Future<CachedBrick> _addRemoteBrickFromRegistry(Brick brick) async {
    final name = brick.name!;
    final version = await _resolveBrickVersion(brick);
    final resolvedBrick = Brick.version(name: name, version: version);
    final dirName = '${name}_$version';
    final directory = Directory(
      p.join(rootDir.path, 'hosted', hostedUri.authority, dirName),
    );
    final directoryExists = directory.existsSync();
    final directoryIsNotEmpty =
        directoryExists && directory.listSync(recursive: true).isNotEmpty;

    /// Use cached version if exists.
    if (directoryExists && directoryIsNotEmpty) {
      final localPath = canonicalize(directory.path);
      _cache[name] = localPath;
      return CachedBrick(brick: resolvedBrick, path: localPath);
    }

    if (directoryExists) await directory.delete(recursive: true);

    await directory.create(recursive: true);
    await _download(resolvedBrick, directory);

    final brickYaml = File(p.join(directory.path, BrickYaml.file));
    final yaml = checkedYamlDecode(
      brickYaml.readAsStringSync(),
      (m) => BrickYaml.fromJson(m!),
    );

    _verifyMasonVersionConstraint(yaml);

    final localPath = canonicalize(directory.path);
    _cache[name] = localPath;
    return CachedBrick(brick: resolvedBrick, path: localPath);
  }

  Future<String> _resolveBrickVersion(Brick brick) async {
    final _version = brick.location.version;
    if (_version != null) {
      try {
        final version = Version.parse(_version);
        return version.toString();
      } catch (_) {}
    }
    final constraint = VersionConstraint.parse(_version ?? 'any');
    final uri = Uri.parse('$hostedUri/api/v1/bricks/${brick.name}');

    late final http.Response response;
    try {
      response = await http.get(uri);
    } catch (_) {
      throw BrickResolveVersionException(
        'Unable to fetch versions for brick "${brick.name}".',
      );
    }
    if (response.statusCode == 404) {
      throw BrickResolveVersionException(
        'Brick "${brick.name}" does not exist.',
      );
    }

    if (response.statusCode != 200) {
      throw BrickResolveVersionException(
        'Unable to fetch versions for brick "${brick.name}".',
      );
    }

    late final Map body;
    late final Version latestVersion;
    try {
      body = json.decode(response.body) as Map;
      final latest = body['latest'] as Map;
      final _latestVersion = latest['version'] as String;
      latestVersion = Version.parse(_latestVersion);
    } catch (_) {
      throw BrickResolveVersionException(
        'Unable to parse latest version of brick "${brick.name}".',
      );
    }

    if (constraint.isAny) return latestVersion.toString();
    if (constraint.allows(latestVersion)) return latestVersion.toString();

    late final List<Version> versions;
    try {
      final _versions = body['versions'] as List;
      versions = _versions
          .map((dynamic v) => Version.parse((v as Map)['version'] as String))
          .toList()
        ..sort(Version.antiprioritize);
    } catch (_) {
      throw BrickResolveVersionException(
        'Unable to parse available versions for brick "${brick.name}".',
      );
    }

    for (final version in versions) {
      if (constraint.allows(version)) return version.toString();
    }

    throw BrickUnsatisfiedVersionConstraint(
      '"${brick.name}: $constraint" '
      "doesn't match any versions.",
    );
  }

  Future<void> _download(Brick brick, Directory directory) async {
    final uri = Uri.parse(
      '$hostedUri/api/v1/bricks/${brick.name}/versions/${brick.location.version}.bundle',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw BrickNotFoundException(uri.toString());
    }

    final bundle = await MasonBundle.fromUniversalBundle(response.bodyBytes);

    unpackBundle(bundle, directory);
  }

  /// Bundled subdirectory within the mason cache.
  static Directory get bundled => Directory(p.join(rootDir.path, 'bundled'));

  /// Global subdirectory within the mason cache.
  static Directory get globalDir => Directory(p.join(rootDir.path, 'global'));

  /// The uri of the registry where bricks are hosted.
  static Uri get hostedUri {
    final environment = testEnvironment ?? Platform.environment;
    return Uri.parse(
      environment['MASON_HOSTED_URL'] ?? 'https://registry.brickhub.dev',
    );
  }

  /// Root mason cache directory
  static Directory get rootDir {
    final environment = testEnvironment ?? Platform.environment;
    final isWindows = testIsWindows ?? Platform.isWindows;
    if (environment.containsKey('MASON_CACHE')) {
      return Directory(environment['MASON_CACHE']!);
    } else if (isWindows) {
      final appData = environment['APPDATA']!;
      final appDataCacheDir = Directory(p.join(appData, 'Mason', 'Cache'));
      if (appDataCacheDir.existsSync()) return Directory(appDataCacheDir.path);
      final localAppData = environment['LOCALAPPDATA']!;
      return Directory(p.join(localAppData, 'Mason', 'Cache'));
    } else {
      return Directory(p.join(environment['HOME']!, '.mason-cache'));
    }
  }
}

String _encodedGitDir(GitPath git, String commitHash) {
  final name = p.basenameWithoutExtension(git.url);
  final path = git.url.replaceAll(r'\', '/');
  final url = base64.encode(utf8.encode(path));
  return '${name}_${url}_$commitHash';
}

void _verifyMasonVersionConstraint(BrickYaml brickYaml) {
  if (!isBrickCompatibleWithMason(brickYaml)) {
    throw BrickIncompatibleMasonVersion(
      brickName: brickYaml.name,
      constraint: brickYaml.environment.mason,
    );
  }
}
