import 'package:json_annotation/json_annotation.dart';

part 'mason_configuration.g.dart';

/// {@template mason_configuration}
/// Mason configuration yaml file which contains metadata
/// used when interacting with the mason CLI.
/// {@endtemplate}
@JsonSerializable()
class MasonConfiguration {
  /// {@macro mason_configuration}
  const MasonConfiguration();

  /// Converts [Map] to [MasonConfiguration]
  factory MasonConfiguration.fromJson(Map<dynamic, dynamic> json) =>
      _$MasonConfigurationFromJson(json);

  /// Converts [MasonConfiguration] to [Map]
  Map<dynamic, dynamic> toJson() => _$MasonConfigurationToJson(this);
}
