import 'dart:collection';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// A file that defines what brick files or directories should be ignored during
/// bundling.
///
/// Only those directories and files under `__brick__` can be ignored.
///
/// For example, given the following brick directory:
///
/// ```txt
/// __brick__/
/// ├─ HELLO.md
/// └─ goodbye.dart
/// brick.yaml
/// .brickignore
/// README.md
/// ```
///
/// And the following `.brickignore` file content:
///
/// ```txt
/// **.md
/// ```
///
/// The `HELLO.md` file will be ignored during bundling, but `goodbye.dart` will
/// not be ignored. Those other files not under `__brick__` are not bundled,
/// hence they can not be ignored.
///
/// See also:
///
/// * [createBundle], which creates a [MasonBundle] from a brick directory.
@internal
class BrickIgnore {
  BrickIgnore._({
    required Iterable<Glob> globs,
    required String path,
    required String brickDirectoryPath,
  })  : _globs = UnmodifiableListView(globs),
        _path = path,
        _brickDirectoryPath = brickDirectoryPath;

  /// Creates a [BrickIgnore] from a [File].
  factory BrickIgnore.fromFile(File file) {
    final lines = file.readAsLinesSync();
    final globs = lines.map(Glob.new);

    final brickDirectoryPath = path.join(file.parent.path, BrickYaml.dir);

    return BrickIgnore._(
      globs: globs,
      path: file.path,
      brickDirectoryPath: brickDirectoryPath,
    );
  }

  /// The name of the file to be created at the root of the brick.
  /// `brick.yaml`
  static const file = '.brickignore';

  final UnmodifiableListView<Glob> _globs;

  /// The absolute path to the ignore file.
  final String _path;

  /// The absolute absolute path to the directory where all brick templated
  /// files are located.
  ///
  /// See also:
  ///
  /// * [BrickYaml.dir], which is the name of the directory where the templated
  /// brick files are located.
  final String _brickDirectoryPath;

  /// Whether or not the [filePath] is ignored.
  ///
  /// Immediately returns false if the [filePath] is not within the brick
  /// directory (`__brick__`). Otherwise, checks if the [filePath] matches
  /// any of the globs in the ignore file.
  bool isIgnored(String filePath) {
    if (!path.isWithin(_brickDirectoryPath, filePath)) return false;

    final relativePath = path.relative(filePath, from: path.dirname(_path));
    return _globs.any((glob) => glob.matches(relativePath));
  }
}
