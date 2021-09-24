import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

import 'brick_yaml.dart';
import 'command.dart';
import 'exception.dart';
import 'git.dart';
import 'mason_yaml.dart';

/// {@template write_brick_exception}
/// Thrown when an error occurs while writing a brick to cache.
/// {@endtemplate}
class WriteBrickException extends MasonException {
  /// {@macro write_brick_exception}
  const WriteBrickException(String message) : super(message);
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

  /// Map of Brick to local path for bricks.
  late Map<String, String> _cache;

  /// Associated bricks.json file
  late File _bricksJsonFile;

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
    return Map.castFrom<dynamic, dynamic, String, String>(
      json.decode(content) as Map,
    );
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
    if (brick.path != null) {
      final path = brick.path!;
      final name = p.basenameWithoutExtension(path);
      final hash = sha256.convert(utf8.encode(path));
      final key = '${name}_$hash';
      return key;
    }
    if (brick.git != null) {
      final path =
          p.join(brick.git!.url, brick.git!.path).replaceAll(r'\', r'/');
      final name = p.basenameWithoutExtension(path);
      final hash = sha256.convert(utf8.encode(path));
      final key = brick.git!.ref != null
          ? '${name}_${brick.git!.ref}_$hash'
          : '${name}_$hash';
      return key;
    }
    return null;
  }

  /// Returns the local path to the brick if it is included in the cache.
  /// Returns `null` if the brick has not been cached.
  String? getPath(Brick brick) => _cache[_getKey(brick)];

  /// Caches brick if necessary and updates `bricks.json`.
  /// Returns the local path to the brick.
  Future<String> add(Brick brick) async {
    final key = _getKey(brick);
    if (key == null) {
      throw const WriteBrickException(
        'Brick must contain either a path or a git url',
      );
    }

    final path = brick.path;
    if (path != null) {
      final brickYaml = File(p.join(path, BrickYaml.file));
      if (!brickYaml.existsSync()) {
        throw BrickNotFoundException(p.canonicalize(path));
      }
      final remoteDir = getPath(brick);
      if (remoteDir != null) return remoteDir;
      return _addLocalBrick(path);
    }

    return _addRemoteBrick(brick.git!);
  }

  /// Writes local brick at [path] to cache
  /// and returns the local path to the brick.
  String _addLocalBrick(String path) {
    final localPath = p.canonicalize(path);
    _cache[_getKey(Brick(path: path))!] = localPath;
    return localPath;
  }

  /// Writes remote brick at [gitPath] to cache
  /// and returns the local path to the brick.
  Future<String> _addRemoteBrick(GitPath gitPath) async {
    final key = _getKey(Brick(git: gitPath))!;
    final dirName = _getKey(
      Brick(git: GitPath(gitPath.url, ref: gitPath.ref)),
    )!;
    final directory = Directory(p.join(rootDir.path, 'git', dirName));
    final directoryExists = directory.existsSync();
    final directoryIsNotEmpty = directoryExists
        ? directory.listSync(recursive: true).isNotEmpty
        : false;

    void _ensureRemoteBrickExists(Directory directory, GitPath gitPath) {
      final brickYaml = File(
        p.join(directory.path, gitPath.path, BrickYaml.file),
      );
      if (!brickYaml.existsSync()) {
        directory.deleteSync(recursive: true);
        throw BrickNotFoundException('${gitPath.url}/${gitPath.path}');
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
      _cache[key] = directory.path;
      return directory.path;
    }

    if (directoryExists) await directory.delete(recursive: true);

    await directory.create(recursive: true);
    await _clone(gitPath, directory);
    _ensureRemoteBrickExists(directory, gitPath);
    _cache[key] = directory.path;
    return directory.path;
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

  /// Global subdirectory within the mason cache.
  static Directory get globalDir => Directory(p.join(rootDir.path, 'global'));

  /// Root mason cache directory
  static Directory get rootDir {
    if (Platform.environment.containsKey('MASON_CACHE')) {
      return Directory(Platform.environment['MASON_CACHE']!);
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA']!;
      final appDataCacheDir = Directory(p.join(appData, 'Mason', 'Cache'));
      if (appDataCacheDir.existsSync()) return Directory(appDataCacheDir.path);
      final localAppData = Platform.environment['LOCALAPPDATA']!;
      return Directory(p.join(localAppData, 'Mason', 'Cache'));
    } else {
      return Directory(p.join(Platform.environment['HOME']!, '.mason-cache'));
    }
  }
}
