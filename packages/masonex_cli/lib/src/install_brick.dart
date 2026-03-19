import 'dart:convert';

import 'package:masonex/masonex.dart';
import 'package:masonex_cli/src/command.dart';
import 'package:path/path.dart' as p;

/// Mixin on [MasonexCommand] which adds support for installing bricks.
mixin InstallBrickMixin on MasonexCommand {
  /// Installs all bricks either locally or globally depending on [global].
  /// If [upgrade] is true, bricks are upgraded to the latest version
  /// and the lock file is regenerated.
  Future<void> getBricks({bool upgrade = false, bool global = false}) async {
    final bricksJson = global ? globalBricksJson : localBricksJson;
    if (bricksJson == null) throw const MasonexYamlNotFoundException();
    final lockJson = global ? globalMasonexLockJson : localMasonexLockJson;
    final resolvedBricks = <String, BrickLocation>{};

    Future<CachedBrick> _resolveBrickEntry(
      MapEntry<String, BrickLocation> entry,
    ) async {
      return () async {
        final location = resolveBrickLocation(
          location: entry.value,
          lockedLocation: upgrade ? null : lockJson.bricks[entry.key],
        );
        final masonexYamlFile = global ? globalMasonexYamlFile : localMasonexYamlFile;
        final normalizedLocation = location.path != null
            ? BrickLocation(
                path: canonicalize(
                  p.join(masonexYamlFile.parent.path, location.path),
                ),
              )
            : location;
        final cachedBrick = await bricksJson.add(
          Brick(name: entry.key, location: normalizedLocation),
        );
        resolvedBricks.addAll(
          <String, BrickLocation>{entry.key: cachedBrick.brick.location},
        );
        final generator = await MasonexGenerator.fromBrick(
          Brick.path(cachedBrick.path),
        );
        await generator.hooks.compile();
        return cachedBrick;
      }();
    }

    try {
      if (upgrade) bricksJson.clear();
      final masonexYaml = global ? globalMasonexYaml : localMasonexYaml;
      if (masonexYaml.bricks.entries.isNotEmpty) {
        final entries = _BrickEntries.fromBricks(masonexYaml.bricks);

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
      final masonexLockJsonFile =
          global ? globalMasonexLockJsonFile : localMasonexLockJsonFile;
      await masonexLockJsonFile.writeAsString(
        json.encode(MasonexLockJson(bricks: resolvedBricks.sorted())),
      );
    }
  }
}

/// Resolves the correct [BrickLocation] given the
/// provided [location] (masonex.yaml) and [lockedLocation] (masonex-lock.json).
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
  final masonexYamlVersion = VersionConstraint.parse(location.version!);
  if (masonexYamlVersion.allows(lockedVersion)) return lockedLocation;
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
