import 'dart:convert';

import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';

/// Mixin on [MasonCommand] which adds support for
/// installing all bricks registered in the nearest mason.yaml.
mixin GetBricksMixin on MasonCommand {
  /// Installs all bricks registered in nearest mason.yaml.
  Future<void> getBricks() async {
    final bricksJson = localBricksJson;
    if (bricksJson == null) throw const MasonYamlNotFoundException();
    final lockJson = masonLockJson;
    final resolvedBricks = <String, BrickLocation>{};
    final getDone = logger.progress('Getting bricks');
    try {
      bricksJson.clear();
      if (masonYaml.bricks.entries.isNotEmpty) {
        await Future.forEach<MapEntry<String, BrickLocation>>(
          masonYaml.bricks.entries,
          (entry) async {
            final location = _resolveBrickLocation(
              masonYamlLocation: entry.value,
              lockedLocation: lockJson?.bricks[entry.key],
            );
            final cachedBrick = await bricksJson.add(
              Brick(name: entry.key, location: location),
            );
            resolvedBricks.addAll(
              <String, BrickLocation>{entry.key: cachedBrick.brick.location},
            );
          },
        );
      }
    } finally {
      getDone();
      await bricksJson.flush();
      await masonLockJsonFile.writeAsString(
        json.encode(MasonLockJson(bricks: resolvedBricks)),
      );
    }
  }
}

BrickLocation _resolveBrickLocation({
  required BrickLocation masonYamlLocation,
  required BrickLocation? lockedLocation,
}) {
  if (lockedLocation == null) return masonYamlLocation;

  if (masonYamlLocation.path != null) return masonYamlLocation;

  if (masonYamlLocation.git != null) {
    if (lockedLocation.git == null) return masonYamlLocation;
    if (lockedLocation.git!.similarTo(masonYamlLocation.git!)) {
      return lockedLocation;
    }
    return masonYamlLocation;
  }

  if (lockedLocation.version == null) return masonYamlLocation;
  final lockedVersion = Version.parse(lockedLocation.version!);
  final masonYamlVersion = VersionConstraint.parse(masonYamlLocation.version!);
  if (masonYamlVersion.allows(lockedVersion)) return lockedLocation;
  return masonYamlLocation;
}

extension on GitPath {
  bool similarTo(GitPath other) {
    return url == other.url && path == other.path;
  }
}
