import 'package:mason/mason.dart';

/// Returns whether the current [brickYaml] is compatible
/// with the current version of mason.
bool isBrickCompatibleWithMason(BrickYaml brickYaml) {
  final currentMasonVersion = Version.parse(packageVersion);
  final masonVersionConstraint = VersionConstraint.parse(
    brickYaml.environment.mason,
  );

  return masonVersionConstraint.allows(currentMasonVersion);
}
