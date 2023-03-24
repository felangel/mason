import 'dart:convert';

import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:path/path.dart' as p;

/// Mixin on [MasonCommand] which adds support for installing bricks.
mixin InstallBrickMixin on MasonCommand {
  /// Installs all bricks either locally or globally depending on [global].
  /// If [upgrade] is true, bricks are upgraded to the latest version
  /// and the lock file is regenerated.
  Future<void> getBricks({bool upgrade = false, bool global = false}) async {
    final bricksJson = global ? globalBricksJson : localBricksJson;
    if (bricksJson == null) throw const MasonYamlNotFoundException();
    final lockJson = global ? globalMasonLockJson : localMasonLockJson;
    final resolvedBricks = <String, BrickLocation>{};

    Future<CachedBrick> _resolveBrickEntry(
      MapEntry<String, BrickLocation> entry,
    ) async {
      return () async {
        final location = resolveBrickLocation(
          location: entry.value,
          lockedLocation: upgrade ? null : lockJson.bricks[entry.key],
        );
        final masonYamlFile = global ? globalMasonYamlFile : localMasonYamlFile;
        final normalizedLocation = location.path != null
            ? BrickLocation(
                path: canonicalize(
                  p.join(masonYamlFile.parent.path, location.path),
                ),
              )
            : location;
        final cachedBrick = await bricksJson.add(
          Brick(name: entry.key, location: normalizedLocation),
        );
        resolvedBricks.addAll(
          <String, BrickLocation>{entry.key: cachedBrick.brick.location},
        );
        final generator = await MasonGenerator.fromBrick(
          Brick.path(cachedBrick.path),
        );
        await generator.hooks.compile();
        return cachedBrick;
      }();
    }

    try {
      if (upgrade) bricksJson.clear();
      final masonYaml = global ? globalMasonYaml : localMasonYaml;
      if (masonYaml.bricks.entries.isNotEmpty) {
        final entries = _BrickEntries.fromBricks(masonYaml.bricks);

        Future<void> _resolveGitBrickEntries(
          MapEntry<String, List<MapEntry<String, BrickLocation>>> entry,
        ) async {
          final firstBrick = entry.value.first;
          final cachedBrick = await _resolveBrickEntry(firstBrick);
          final commitHash = cachedBrick.brick.location.git!.ref;

          if (entry.value.length > 1) {
            for (final entry in entry.value.sublist(1)) {
              final git = entry.value.git!;
              await _resolveBrickEntry(
                MapEntry(
                  entry.key,
                  BrickLocation(
                    git: GitPath(git.url, path: git.path, ref: commitHash),
                  ),
                ),
              );
            }
          }
        }

        await Future.wait([
          ...entries.gitEntries.entries.map(_resolveGitBrickEntries),
          ...entries.nonGitEntries.map(_resolveBrickEntry),
        ]);
      }
    } finally {
      await bricksJson.flush();
      final masonLockJsonFile =
          global ? globalMasonLockJsonFile : localMasonLockJsonFile;
      await masonLockJsonFile.writeAsString(
        json.encode(MasonLockJson(bricks: resolvedBricks.sorted())),
      );
    }
  }
}

/// Resolves the correct [BrickLocation] given the
/// provided [location] (mason.yaml) and [lockedLocation] (mason-lock.json).
BrickLocation resolveBrickLocation({
  required BrickLocation location,
  required BrickLocation? lockedLocation,
}) {
  if (lockedLocation == null) return location;
  if (location.path != null) return location;

  if (location.git != null) {
    if (lockedLocation.git == null) return location;
    if (lockedLocation.git!.similarTo(location.git!)) {
      return lockedLocation;
    }
    return location;
  }

  if (lockedLocation.version == null) return location;
  final lockedVersion = Version.parse(lockedLocation.version!);
  final masonYamlVersion = VersionConstraint.parse(location.version!);
  if (masonYamlVersion.allows(lockedVersion)) return lockedLocation;
  return location;
}

extension on GitPath {
  bool similarTo(GitPath other) {
    return url == other.url && path == other.path;
  }
}

extension on Map<String, BrickLocation> {
  Map<String, BrickLocation> sorted() {
    return Map.fromEntries(
      entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
}

class _BrickEntries {
  factory _BrickEntries.fromBricks(Map<String, BrickLocation> bricks) {
    final nonGitEntries = <MapEntry<String, BrickLocation>>[];
    final gitEntries = <String, List<MapEntry<String, BrickLocation>>>{};

    for (final entry in bricks.entries) {
      if (entry.value.git != null) {
        final path = entry.value.git!.url.replaceAll(r'\', '/');
        final url = base64.encode(utf8.encode(path));
        final key = '${url}_${entry.value.git!.ref ?? ''}';
        if (gitEntries.containsKey(key)) {
          gitEntries[key]!.add(entry);
        } else {
          gitEntries[key] = [entry];
        }
      } else {
        nonGitEntries.add(entry);
      }
    }

    return _BrickEntries._(
      nonGitEntries: nonGitEntries,
      gitEntries: gitEntries,
    );
  }

  const _BrickEntries._({
    this.nonGitEntries = const [],
    this.gitEntries = const {},
  });

  final List<MapEntry<String, BrickLocation>> nonGitEntries;
  final Map<String, List<MapEntry<String, BrickLocation>>> gitEntries;
}
