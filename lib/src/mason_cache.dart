import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// {@template mason_cache}
/// A local cache for mason bricks.
///
/// This cache contains local paths to all bricks.
/// {@endtemplate}
class MasonCache {
  /// {@macro mason_cache}
  MasonCache.empty({String rootDir}) : rootDir = rootDir ?? _masonCacheDir();

  /// Create a [MasonCache] which is populated with bricks
  /// from the current directory ([path]).
  MasonCache(String path) : rootDir = _masonCacheDir() {
    _fromBricks(path);
  }

  /// Mapping between remote and local brick paths.
  var _cache = <String, String>{};

  /// Removes all key/value pairs from the cache.
  void clear() => _cache.clear();

  /// hydrates cache based on `.bricks` found in [path]
  void _fromBricks(String path) {
    final bricks = File(p.join(path, '.bricks'));
    if (!bricks.existsSync()) return;
    final content = bricks.readAsStringSync();
    _cache = Map.castFrom<dynamic, dynamic, String, String>(
      json.decode(content) as Map,
    );
  }

  /// Encodes entire cache contents.
  String get encode => json.encode(_cache);

  /// The root directory where this brick cache is located.
  final String rootDir;

  /// Returns the local path to the brick if it is included in the cache.
  /// Returns `null` if the brick has not been cached.
  String read(String remote) {
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
}

String _masonCacheDir() {
  if (Platform.environment.containsKey('MASON_CACHE')) {
    return Platform.environment['MASON_CACHE'];
  } else if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    final appDataCacheDir = Directory(p.join(appData, 'Mason', 'Cache'));
    if (appDataCacheDir.existsSync()) {
      return appDataCacheDir.path;
    }
    final localAppData = Platform.environment['LOCALAPPDATA'];
    return p.join(localAppData, 'Mason', 'Cache');
  } else {
    return '${Platform.environment['HOME']}/.mason-cache';
  }
}
