import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

part 'mason_yaml.g.dart';

/// {@template mason_yaml}
/// Mason configuration yaml file which contains metadata
/// used when interacting with the Mason CLI.
/// {@endtemplate}
@JsonSerializable()
class MasonYaml {
  /// {@macro mason_yaml}
  const MasonYaml(Map<String, Brick>? bricks)
      : bricks = bricks ?? const <String, Brick>{};

  /// Converts [Map] to [MasonYaml]
  factory MasonYaml.fromJson(Map<dynamic, dynamic> json) =>
      _$MasonYamlFromJson(json);

  /// Converts [MasonYaml] to [Map]
  Map<dynamic, dynamic> toJson() => _$MasonYamlToJson(this);

  /// static constant for mason configuration file name.
  /// `mason.yaml`
  static const file = 'mason.yaml';

  /// static constant for an empty `mason.yaml` file.
  static const empty = MasonYaml(<String, Brick>{});

  /// [Map] of [Brick] alias to [Brick] instances.
  final Map<String, Brick> bricks;

  /// Finds nearest ancestor `mason.yaml` file
  /// relative to the [cwd].
  static File? findNearest(Directory cwd) {
    Directory? prev;
    var dir = cwd;
    while (prev?.path != dir.path) {
      final masonConfig = File(p.join(dir.path, 'mason.yaml'));
      if (masonConfig.existsSync()) return masonConfig;
      prev = dir;
      dir = dir.parent;
    }
    return null;
  }
}

/// {@template brick}
/// Contains metadata for a reusable brick template.
///
/// Used by [MasonYaml].
/// {@endtemplate}
@JsonSerializable()
class Brick {
  /// {@macro brick}
  const Brick({this.path, this.git});

  /// Converts a [Map] to a [Brick].
  factory Brick.fromJson(Map<dynamic, dynamic> json) => _$BrickFromJson(json);

  /// Converts [Brick] to [Map]
  Map<dynamic, dynamic> toJson() => _$BrickToJson(this);

  /// The local brick template path.
  final String? path;

  /// Git brick template path.
  final GitPath? git;
}

/// {@template git_path}
/// Path to templates in git.
/// {@endtemplate}
@JsonSerializable()
class GitPath {
  /// {@macro git_path}
  const GitPath(this.url, {this.path, this.ref});

  /// Converts [Map] to [MasonYaml]
  factory GitPath.fromJson(Map<dynamic, dynamic> json) =>
      _$GitPathFromJson(json);

  /// Converts [GitPath] to [Map]
  Map<dynamic, dynamic> toJson() => _$GitPathToJson(this);

  /// The local brick template path.
  final String url;

  /// Path in repository. Defaults to /.
  final String? path;

  /// Anything that git can use to identify a commit.
  /// Can be a branch name, tag, or commit hash.
  final String? ref;
}
