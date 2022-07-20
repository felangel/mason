import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;

part 'mason_yaml.g.dart';

/// {@template mason_yaml}
/// Mason configuration yaml file which contains metadata
/// used when interacting with the Mason CLI.
/// {@endtemplate}
@JsonSerializable()
class MasonYaml {
  /// {@macro mason_yaml}
  const MasonYaml(Map<String, BrickLocation>? bricks)
      : bricks = bricks ?? const <String, BrickLocation>{};

  /// Converts [Map] to [MasonYaml]
  factory MasonYaml.fromJson(Map<dynamic, dynamic> json) =>
      _$MasonYamlFromJson(json);

  /// Converts [MasonYaml] to [Map]
  Map<dynamic, dynamic> toJson() => _$MasonYamlToJson(this);

  /// static constant for mason configuration file name.
  /// `mason.yaml`
  static const file = 'mason.yaml';

  /// static constant for an empty `mason.yaml` file.
  static const empty = MasonYaml(<String, BrickLocation>{});

  /// [Map] of [BrickLocation] alias to [BrickLocation] instances.
  final Map<String, BrickLocation> bricks;

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

/// {@template brick_location}
/// Contains metadata for the location of a reusable brick template.
///
/// Used by [MasonYaml].
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

  /// Converts [Map] to [MasonYaml]
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
