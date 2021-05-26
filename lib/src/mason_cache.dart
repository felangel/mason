import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'git.dart';
import 'mason_yaml.dart';

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

  /// Downloads remote brick at [gitPath] to local `.brick-cache`
  /// and returns the local path to the brick.
  Future<String> downloadRemoteBrick(GitPath gitPath) async {
    final dirName =
        gitPath.ref != null ? '${gitPath.url}-${gitPath.ref}' : gitPath.url;
    final directory = Directory(p.join(rootDir, 'git', dirName));
    final directoryExists = await directory.exists();
    final directoryIsNotEmpty = directoryExists
        ? directory.listSync(recursive: true).isNotEmpty
        : false;

    if (directoryExists && directoryIsNotEmpty) {
      write(gitPath.url, directory.path);
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
    write(gitPath.url, directory.path);
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
