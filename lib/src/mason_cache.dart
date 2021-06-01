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
  /// {@macro mason_cache}
  MasonCache.empty({String? rootDir}) : rootDir = rootDir ?? _masonCacheDir();

  /// Create a [MasonCache] which is populated with bricks
  /// from the current directory ([bricksJson]).
  MasonCache(File bricksJson) : rootDir = _masonCacheDir() {
    _fromBricks(bricksJson);
  }

  /// Mapping between remote and local brick paths.
  var _cache = <String, String>{};

  /// Removes all key/value pairs from the cache.
  /// If [force] is true, all bricks will be removed
  /// from disk in addition to the in-memory cache.
  void clear({bool force = false}) async {
    _cache.clear();
    if (force) {
      try {
        Directory(rootDir).deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  /// Populates cache based on `.mason/bricks.json`.
  void _fromBricks(File bricksJson) {
    if (!bricksJson.existsSync()) return;
    final content = bricksJson.readAsStringSync();
    if (content.isNotEmpty) {
      _cache = Map.castFrom<dynamic, dynamic, String, String>(
        json.decode(content) as Map,
      );
    }
  }

  /// Encodes entire cache contents.
  String get encode => json.encode(_cache);

  /// The root directory where this brick cache is located.
  final String rootDir;

  /// Returns the local path to the brick if it is included in the cache.
  /// Returns `null` if the brick has not been cached.
  String? read(String remote) {
    if (_cache.containsKey(remote)) {
      return _cache[remote];
    }
    return null;
  }

  /// Returns all cache keys.
  Iterable<String> get keys => _cache.keys;

  /// Removes key/value pair for key [remote].
  void remove(String remote) {
    _cache.remove(remote);
  }

  /// Returns the local path to the brick if it is included in the cache.
  /// Returns `null` if the brick has not been cached.
  void write(String remote, String local) {
    _cache[remote] = local;
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
    final remoteDir = read(key);
    if (remoteDir != null) return remoteDir;
    return brick.path != null
        ? _writeLocalBrick(brick.path!)
        : await _writeRemoteBrick(brick.git!);
  }

  /// Writes local brick at [path] to cache
  /// and returns the local path to the brick.
  String _writeLocalBrick(String path) {
    print('path: $path');
    final localPath = p.canonicalize(path);
    print('canonicalized: $localPath');
    write(getKey(Brick(path: path))!, localPath);
    return localPath;
  }

  /// Writes remote brick at [gitPath] to cache
  /// and returns the local path to the brick.
  Future<String> _writeRemoteBrick(GitPath gitPath) async {
    final dirName = getKey(Brick(git: gitPath))!;
    final directory = Directory(p.join(rootDir, 'git', dirName));
    final directoryExists = await directory.exists();
    final directoryIsNotEmpty = directoryExists
        ? directory.listSync(recursive: true).isNotEmpty
        : false;

    if (directoryExists && directoryIsNotEmpty) {
      write(dirName, directory.path);
      return directory.path;
    }

    if (directoryExists) await directory.delete(recursive: true);

    await directory.create(recursive: true);
    await Git.run(['clone', gitPath.url, directory.path]);
    if (gitPath.ref != null) {
      await Git.run(
        ['checkout', gitPath.ref!],
        processWorkingDir: directory.path,
      );
    }
    write(dirName, directory.path);
    return directory.path;
  }
}

String _masonCacheDir() {
  if (Platform.environment.containsKey('MASON_CACHE')) {
    return Platform.environment['MASON_CACHE']!;
  } else if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA']!;
    final appDataCacheDir = Directory(p.join(appData, 'Mason', 'Cache'));
    if (appDataCacheDir.existsSync()) return appDataCacheDir.path;
    final localAppData = Platform.environment['LOCALAPPDATA']!;
    return p.join(localAppData, 'Mason', 'Cache');
  } else {
    return p.join(Platform.environment['HOME']!, '.mason-cache');
  }
}
