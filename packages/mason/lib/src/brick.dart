import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

/// {@template brick}
/// Metadata for a brick template including the name and location.
/// {@endtemplate}
class Brick {
  /// {@macro brick}
  const Brick({
    required this.name,
    required this.location,
  });

  /// Brick from a local path.
  Brick.path(String path)
      : this(
          name: p.basenameWithoutExtension(path),
          location: BrickLocation(path: path),
        );

  /// Brick from a git url.
  Brick.git(GitPath git)
      : this(
          name: p.basenameWithoutExtension(
            p.join(git.url, git.path).replaceAll(r'\', '/'),
          ),
          location: BrickLocation(git: git),
        );

  /// Brick from a version constraint.
  Brick.version({required String name, required String version})
      : this(
          name: name,
          location: BrickLocation(version: version),
        );

  /// The name of the brick.
  final String name;

  /// The location of the brick.
  final BrickLocation location;
}
