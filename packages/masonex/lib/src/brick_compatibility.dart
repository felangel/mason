import 'package:masonex/masonex.dart';

/// Returns whether the current [brickYaml] is compatible
/// with the current version of masonex.
bool isBrickCompatibleWithMasonex(BrickYaml brickYaml) {
  final currentMasonexVersion = Version.parse(packageVersion);
  final masonexVersionConstraint = VersionConstraint.parse(
    brickYaml.environment.masonex,
  );

  return masonexVersionConstraint.allows(currentMasonexVersion);
}
