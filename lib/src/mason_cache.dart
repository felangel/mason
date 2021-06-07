import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

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

/// {@template mason_cache}
/// A local cache for mason bricks.
///
/// This cache contains local paths to all bricks.
/// {@endtemplate}
class MasonCache {
  /// Creates a [MasonCache] instance from the [directory].
  MasonCache({Directory? directory}) : _localDir = directory {
    if (directory != null && directory.path != globalDir.path) {
      _localBricksJson = File(p.join(directory.path, '.mason', 'bricks.json'));
      _localCache = _fromBricksJson(_localBricksJson!);
    }
    if (!globalDir.existsSync()) globalDir..createSync(recursive: true);
    _globalBricksJson = File(p.join(globalDir.path, '.mason', 'bricks.json'));
    _globalCache = _fromBricksJson(_globalBricksJson);
  }

  /// Brick to local path from local bricks.
  Map<String, String>? _localCache;

  /// Brick to local path from global bricks.
  late Map<String, String> _globalCache;

  /// The current cache.
  /// This is the local cache if it exists
  /// otherwise it is the global cache.
  Map<String, String> get _cache => _localCache ?? _globalCache;

  /// Local `bricks.json` file.
  /// This can be null if mason is run from a context
  /// which does not include a `mason.yaml` file.
  File? _localBricksJson;

  /// Global `bricks.json` file.
  late File _globalBricksJson;

  /// The current `bricks.json` file.
  /// This is the local bricks.json file if it exists
  /// otherwise it is the global `bricks.json` file.
  File get _bricksJson => _localBricksJson ?? _globalBricksJson;

  /// Removes all key/value pairs from the cache.
  /// If [force] is true, all bricks will be removed
  /// from disk in addition to the in-memory cache.
  void clear({bool force = false}) async {
    _cache.clear();
    try {
      _bricksJson.deleteSync();
    } catch (_) {}
    try {
      if (force) _cacheDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  /// Populates cache based on `.mason/bricks.json`.
  Map<String, String> _fromBricksJson(File bricksJson) {
    if (!bricksJson.existsSync()) return <String, String>{};
    final content = bricksJson.readAsStringSync();
    if (content.isEmpty) return <String, String>{};
    return Map.castFrom<dynamic, dynamic, String, String>(
      json.decode(content) as Map,
    );
  }

  /// Encodes entire cache contents.
  String get encode => json.encode(_cache);

  /// The local directory where this brick cache is located.
  final Directory? _localDir;

  /// Current cache directory.
  /// `_localDir` if available otherwise `_rootDir`.
  Directory get _cacheDir => _localDir ?? _rootDir;

  /// Returns the local path to the brick if it is included in the cache.
  /// Returns `null` if the brick has not been cached.
  String? read(String remote) {
    if (_cache.containsKey(remote)) return _cache[remote];
    return null;
  }

  /// Removes key/value pair for key [remote].
  void remove(String remote) => _cache.remove(remote);

  /// Returns the local path to the brick if it is included in the cache.
  /// Returns `null` if the brick has not been cached.
  void write(String remote, String local) => _cache[remote] = local;

  /// Flushes cache contents to `brick.json`.
  Future<void> flush() async {
    await _bricksJson.create(recursive: true);
    await _bricksJson.writeAsString(encode);
  }

  /// Returns the cache key for the given [brick].
  /// Return `null` if the [brick] does not have a valid path.
  String? getKey(Brick brick) {
    if (brick.path != null) {
      final name = p.basenameWithoutExtension(brick.path!);
      final hash = sha256.convert(utf8.encode(brick.path!));
      final key = '${name}_$hash';
      return key;
    }
    if (brick.git != null) {
      final name = p.basenameWithoutExtension(brick.git!.url);
      final hash = sha256.convert(utf8.encode(brick.git!.url));
      final key = brick.git!.ref != null
          ? '${name}_${brick.git!.ref}_$hash'
          : '${name}_$hash';
      return key;
    }
    return null;
  }

  /// Caches brick if necessary and updates `bricks.json`.
  Future<String> writeBrick(Brick brick) async {
    final key = getKey(brick);
    if (key == null) {
      throw const WriteBrickException(
        'Brick must contain either a path or a git url',
      );
    }

    if (brick.path != null) {
      final remoteDir = read(key);
      if (remoteDir != null) return remoteDir;
      return _writeLocalBrick(brick.path!);
    }

    return _writeRemoteBrick(brick.git!);
  }

  /// Writes local brick at [path] to cache
  /// and returns the local path to the brick.
  String _writeLocalBrick(String path) {
    final localPath = p.canonicalize(path);
    write(getKey(Brick(path: path))!, localPath);
    return localPath;
  }

  /// Writes remote brick at [gitPath] to cache
  /// and returns the local path to the brick.
  Future<String> _writeRemoteBrick(GitPath gitPath) async {
    final dirName = getKey(Brick(git: gitPath))!;
    final directory = Directory(p.join(_rootDir.path, 'git', dirName));
    final directoryExists = await directory.exists();
    final directoryIsNotEmpty = directoryExists
        ? directory.listSync(recursive: true).isNotEmpty
        : false;

    /// Even if a cached version exists, still try to update.
    /// Fall-back to cached version if update fails.
    if (directoryExists && directoryIsNotEmpty) {
      try {
        final tempDirectory = Directory.systemTemp.createTempSync();
        await _clone(gitPath, tempDirectory);
        await directory.delete(recursive: true);
        await tempDirectory.rename(directory.path);
      } catch (_) {}
      write(dirName, directory.path);
      return directory.path;
    }

    if (directoryExists) await directory.delete(recursive: true);

    await directory.create(recursive: true);
    await _clone(gitPath, directory);
    write(dirName, directory.path);
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
  static Directory get globalDir => Directory(p.join(_rootDir.path, 'global'));

  static Directory get _rootDir {
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
