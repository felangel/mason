import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;

part 'mason_yaml.g.dart';

/// {@template masonex_yaml}
/// Masonex configuration yaml file which contains metadata
/// used when interacting with the Masonex CLI.
/// {@endtemplate}
@JsonSerializable()
class MasonexYaml {
  /// {@macro masonex_yaml}
  const MasonexYaml(Map<String, BrickLocation>? bricks)
      : bricks = bricks ?? const <String, BrickLocation>{};

  /// Converts [Map] to [MasonexYaml]
  factory MasonexYaml.fromJson(Map<dynamic, dynamic> json) =>
      _$MasonexYamlFromJson(json);

  /// Converts [MasonexYaml] to [Map]
  Map<dynamic, dynamic> toJson() => _$MasonexYamlToJson(this);

  /// static constant for masonex configuration file name.
  /// `masonex.yaml`
  static const file = 'masonex.yaml';

  /// static constant for an empty `masonex.yaml` file.
  static const empty = MasonexYaml(<String, BrickLocation>{});

  /// [Map] of [BrickLocation] alias to [BrickLocation] instances.
  final Map<String, BrickLocation> bricks;

  /// Finds nearest ancestor `masonex.yaml` file
  /// relative to the [cwd].
  static File? findNearest(Directory cwd) {
    Directory? prev;
    var dir = cwd;
    while (prev?.path != dir.path) {
      final masonexConfig = File(p.join(dir.path, 'masonex.yaml'));
      if (masonexConfig.existsSync()) return masonexConfig;
      prev = dir;
      dir = dir.parent;
    }
    return null;
  }
}

/// {@template brick_location}
/// Contains metadata for the location of a reusable brick template.
///
/// Used by [MasonexYaml].
/// {@endtemplate}
@JsonSerializable()
class BrickLocation {
  /// {@macro brick_location}
  const BrickLocation({this.path, this.git, this.version});

  /// Converts a [Map] to a [BrickLocation].
  factory BrickLocation.fromJson(dynamic json) {
    if (json is String) return BrickLocation(version: json);
    return _$BrickLocationFromJson(json as Map);
  }

  /// Converts [BrickLocation] to [Map]
  dynamic toJson() {
    if (version != null) return version;
    return _$BrickLocationToJson(this);
  }

  /// The local brick template path.
  final String? path;

  /// Git brick template path.
  final GitPath? git;

  /// Brick version constraint.
  final String? version;
}

/// {@template git_path}
/// Path to templates in git.
/// {@endtemplate}
@JsonSerializable()
class GitPath {
  /// {@macro git_path}
  const GitPath(this.url, {String? path, this.ref}) : path = path ?? '';

  /// Converts [Map] to [MasonexYaml]
  factory GitPath.fromJson(Map<dynamic, dynamic> json) =>
      _$GitPathFromJson(json);

  /// Converts [GitPath] to [Map]
  Map<dynamic, dynamic> toJson() => _$GitPathToJson(this);

  /// The local brick template path.
  final String url;

  /// Path in repository. Defaults to `''` (empty string).
  final String path;

  /// Anything that git can use to identify a commit.
  /// Can be a branch name, tag, or commit hash.
  final String? ref;
}
