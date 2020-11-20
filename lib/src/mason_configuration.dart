import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;

part 'mason_configuration.g.dart';

/// {@template mason_configuration}
/// Mason configuration yaml file which contains metadata
/// used when interacting with the mason CLI.
/// {@endtemplate}
@JsonSerializable()
class MasonConfiguration {
  /// {@macro mason_configuration}
  const MasonConfiguration(this.templates);

  /// Converts [Map] to [MasonConfiguration]
  factory MasonConfiguration.fromJson(Map<dynamic, dynamic> json) =>
      _$MasonConfigurationFromJson(json);

  /// Converts [MasonConfiguration] to [Map]
  Map<dynamic, dynamic> toJson() => _$MasonConfigurationToJson(this);

  /// [Map] of template alias to [MasonTemplate].
  final Map<String, MasonTemplate> templates;

  /// Finds nearest ancestor `mason.yaml` file
  /// relative to the [cwd].
  static File findNearest(Directory cwd) {
    Directory prev;
    var dir = cwd;
    while (prev?.path != dir.path) {
      final masonConfig = File(p.join(dir.path, 'mason.yaml'));
      if (masonConfig.existsSync()) {
        return masonConfig;
      }
      prev = dir;
      dir = dir.parent;
    }
    return null;
  }
}

/// {@template mason_template}
/// Mason Template which contains metadata about the template.
///
/// Used by [MasonConfiguration].
/// {@endtemplate}
@JsonSerializable()
class MasonTemplate {
  /// {@macro mason_template}
  const MasonTemplate({this.path, this.git});

  /// Converts [Map] to [MasonConfiguration]
  factory MasonTemplate.fromJson(Map<dynamic, dynamic> json) =>
      _$MasonTemplateFromJson(json);

  /// Converts [MasonTemplate] to [Map]
  Map<dynamic, dynamic> toJson() => _$MasonTemplateToJson(this);

  /// The local template path.
  final String path;

  /// Git Template configuration.
  final GitPath git;
}

/// {@template git_path}
/// Path to templates in git.
/// {@endtemplate}
@JsonSerializable()
class GitPath {
  /// {@macro git_path}
  const GitPath(this.url, {this.path, this.ref});

  /// Converts [Map] to [MasonConfiguration]
  factory GitPath.fromJson(Map<dynamic, dynamic> json) =>
      _$GitPathFromJson(json);

  /// Converts [GitPath] to [Map]
  Map<dynamic, dynamic> toJson() => _$GitPathToJson(this);

  /// The local template path.
  final String url;

  /// Path in repository. Defaults to /.
  final String path;

  /// Anything that git can use to identify a commit.
  /// Can be a branch name, tag, or commit hash.
  final String ref;
}
