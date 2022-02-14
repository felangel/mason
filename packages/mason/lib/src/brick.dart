import 'package:mason/mason.dart';

/// {@template brick}
/// Metadata for a brick template including the name and location.
/// {@endtemplate}
class Brick {
  /// {@macro brick}
  const Brick({
    this.name,
    required this.location,
  });

  /// Brick from a local path.
  Brick.path(String path) : this(location: BrickLocation(path: path));

  /// Brick from a git url.
  Brick.git(GitPath git) : this(location: BrickLocation(git: git));

  /// Brick from a version constraint.
  Brick.version({required String name, required String version})
      : this(
          name: name,
          location: BrickLocation(version: version),
        );

  /// The name of the brick.
  final String? name;

  /// The location of the brick.
  final BrickLocation location;
}
