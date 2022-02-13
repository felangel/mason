import 'dart:convert';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:mason/mason.dart';
import 'package:mason/src/git.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:universal_io/io.dart';

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
  void remove(Brick brick) {
    final cacheKey = _getKey(brick);
    if (cacheKey != null) _cache.remove(cacheKey);
  }

  /// Flushes cache contents to `bricks.json`.
  Future<void> flush() async {
    await _bricksJsonFile.create(recursive: true);
    await _bricksJsonFile.writeAsString(encode);
  }

  /// Returns the cache key for the given [brick].
  /// Return `null` if the [brick] does not have a valid path.
  String? _getKey(Brick brick) {
    final name = brick.name;
    final location = brick.location;
    if (location.path != null) {
      final hash = sha256.convert(utf8.encode(location.path!));
      final key = '${name}_$hash';
      return key;
    }
    if (location.git != null) {
      final path =
          p.join(location.git!.url, location.git!.path).replaceAll(r'\', '/');
      final hash = sha256.convert(utf8.encode(path));
      final key = location.git!.ref != null
          ? '${name}_${location.git!.ref}_$hash'
          : '${name}_$hash';
      return key;
    }
    if (location.version != null) {
      return '${name}_${location.version}';
    }
    return null;
  }

  /// Returns the local path to the brick if it is included in the cache.
  /// Returns `null` if the brick has not been cached.
  String? getPath(Brick brick) => _cache[_getKey(brick)];

  /// Caches brick if necessary and updates `bricks.json`.
  /// Returns the local path to the brick.
  Future<String> add(Brick brick) async {
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
  String _addLocalBrick(Brick brick) {
    final path = brick.location.path!;
    final brickYaml = File(p.join(path, BrickYaml.file));

    if (!brickYaml.existsSync()) {
      throw BrickNotFoundException(p.canonicalize(path));
    }

    final yaml = checkedYamlDecode(
      brickYaml.readAsStringSync(),
      (m) => BrickYaml.fromJson(m!),
    );

    if (yaml.name != brick.name) {
      throw MasonYamlNameMismatch(
        'Brick name "${brick.name}" '
        'doesn\'t match provided name "${yaml.name}" in ${MasonYaml.file}.',
      );
    }

    final remoteDir = getPath(brick);
    if (remoteDir != null) return remoteDir;
    final localPath = p.canonicalize(brick.location.path!);
    _cache[_getKey(brick)!] = localPath;
    return localPath;
  }

  /// Writes remote brick via git url to cache
  /// and returns the local path to the brick.
  Future<String> _addRemoteBrickFromGit(Brick brick) async {
    final gitPath = brick.location.git!;
    final key = _getKey(brick)!;
    final dirName = _getKey(
      Brick.git(GitPath(gitPath.url, ref: gitPath.ref)),
    )!;
    final directory = Directory(p.join(rootDir.path, 'git', dirName));
    final directoryExists = directory.existsSync();
    final directoryIsNotEmpty =
        directoryExists && directory.listSync(recursive: true).isNotEmpty;

    void _ensureRemoteBrickExists(Directory directory, GitPath gitPath) {
      final brickYaml = File(
        p.join(directory.path, gitPath.path, BrickYaml.file),
      );
      if (!brickYaml.existsSync()) {
        if (directory.existsSync()) directory.deleteSync(recursive: true);
        throw BrickNotFoundException('${gitPath.url}/${gitPath.path}');
      }
      final yaml = checkedYamlDecode(
        brickYaml.readAsStringSync(),
        (m) => BrickYaml.fromJson(m!),
      );

      if (yaml.name != brick.name) {
        throw MasonYamlNameMismatch(
          'Brick name "${brick.name}" '
          'doesn\'t match provided name "${yaml.name}" in ${MasonYaml.file}.',
        );
      }
    }

    /// Even if a cached version exists, still try to update.
    /// Fall-back to cached version if update fails.
    if (directoryExists && directoryIsNotEmpty) {
      try {
        final tempDirectory = Directory.systemTemp.createTempSync();
        await _clone(gitPath, tempDirectory);
        await directory.delete(recursive: true);
        await tempDirectory.rename(directory.path);
      } catch (_) {}
      _ensureRemoteBrickExists(directory, gitPath);
      final localPath = p.canonicalize(p.join(directory.path, gitPath.path));
      _cache[key] = localPath;
      return localPath;
    }

    if (directoryExists) await directory.delete(recursive: true);

    await directory.create(recursive: true);
    await _clone(gitPath, directory);
    _ensureRemoteBrickExists(directory, gitPath);
    final localPath = p.canonicalize(p.join(directory.path, gitPath.path));
    _cache[key] = localPath;
    return localPath;
  }

  Future<void> _clone(GitPath gitPath, Directory directory) async {
    await Git.run(['clone', gitPath.url, directory.path]);
    if (gitPath.ref != null) {
      await Git.run(
        ['checkout', gitPath.ref!],
        processWorkingDir: directory.path,
      );
    }
  }

  /// Writes remote brick from registry to cache
  /// and returns the local path to the brick.
  Future<String> _addRemoteBrickFromRegistry(Brick brick) async {
    final version = await _resolveBrickVersion(brick);
    final resolvedBrick = Brick.version(name: brick.name, version: version);
    final key = _getKey(resolvedBrick)!;
    final directory = Directory(p.join(rootDir.path, 'hosted', hostedUrl, key));
    final directoryExists = directory.existsSync();
    final directoryIsNotEmpty =
        directoryExists && directory.listSync(recursive: true).isNotEmpty;

    /// Use cached version if exists.
    if (directoryExists && directoryIsNotEmpty) {
      _cache[key] = directory.path;
      return directory.path;
    }

    if (directoryExists) await directory.delete(recursive: true);

    await directory.create(recursive: true);
    await _download(resolvedBrick, directory);
    _cache[key] = directory.path;
    return directory.path;
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
    final uri = Uri.parse('https://$hostedUrl/api/v1/bricks/${brick.name}');

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
      'https://$hostedUrl/api/v1/bricks/${brick.name}/versions/${brick.location.version}.bundle',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw BrickNotFoundException(uri.toString());
    }

    final bundle = MasonBundle.fromUniversalBundle(response.bodyBytes);
    unpackBundle(bundle, directory);
  }

  /// Global subdirectory within the mason cache.
  static Directory get globalDir => Directory(p.join(rootDir.path, 'global'));

  /// The location of the registry where bricks are hosted.
  static String get hostedUrl {
    final environment = testEnvironment ?? Platform.environment;
    return environment['MASON_HOSTED_URL'] ?? 'registry.brickhub.dev';
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
