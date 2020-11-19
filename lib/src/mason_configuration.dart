import 'package:json_annotation/json_annotation.dart';

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
}

/// {@template mason_template}
/// Mason Template which contains metadata about the template.
///
/// Used by [MasonConfiguration].
/// {@endtemplate}
@JsonSerializable()
class MasonTemplate {
  /// {@macro mason_template}
  const MasonTemplate(this.path);

  /// Converts [Map] to [MasonConfiguration]
  factory MasonTemplate.fromJson(Map<dynamic, dynamic> json) =>
      _$MasonTemplateFromJson(json);

  /// Converts [MasonTemplate] to [Map]
  Map<dynamic, dynamic> toJson() => _$MasonTemplateToJson(this);

  /// The template path.
  /// It can be either a remote path or a local path.
  final String path;
}
