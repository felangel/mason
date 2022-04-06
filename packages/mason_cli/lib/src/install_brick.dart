import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';

/// Mixin on [MasonCommand] which adds support for installing bricks.
mixin InstallBrickMixin on MasonCommand {
  /// Installs a specific brick and returns the [CachedBrick] reference.
  Future<CachedBrick> addBrick(Brick brick, {bool global = false}) async {
    final bricksJson = global ? globalBricksJson : localBricksJson;
    if (bricksJson == null) {
      throw UsageException('bricks.json not found', usage);
    }

    final lockFile = global ? globalMasonLockJsonFile : masonLockJsonFile;
    final lockJson = global ? globalMasonLockJson : masonLockJson;
    final installDone = logger.progress('Installing ${brick.name}');
    try {
      final location = resolveBrickLocation(
        location: brick.location,
        lockedLocation: lockJson.bricks[brick.name],
      );
      final cachedBrick = await bricksJson.add(
        Brick(name: brick.name, location: location),
      );
      await bricksJson.flush();
      await lockFile.writeAsString(
        json.encode(
          MasonLockJson(
            bricks: {
              ...lockJson.bricks,
              brick.name!: cachedBrick.brick.location
            },
          ),
        ),
      );
      return cachedBrick;
    } finally {
      installDone();
    }
  }

  /// Installs all bricks registered in nearest `mason.yaml`.
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
            final location = resolveBrickLocation(
              location: entry.value,
              lockedLocation: lockJson.bricks[entry.key],
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
