import 'dart:io';

import 'package:path/path.dart' as p;

/// {@template mason_cache}
/// The system-wide cache of downloaded mason bricks.
///
/// This cache contains all bricks that are downloaded from the internet.
/// Bricks that are available locally (e.g. path dependencies) don't use this
/// cache.
/// {@endtemplate}
class MasonCache {
  /// {@macro mason_cache}
  MasonCache({String rootDir}) : rootDir = rootDir ?? _masonCacheDir();

  /// The root directory where this brick cache is located.
  final String rootDir;
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
