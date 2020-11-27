import 'package:json_annotation/json_annotation.dart';

part 'brick_yaml.g.dart';

/// {@template mason_yaml}
/// Brick yaml file which contains metadata required to create
/// a `MasonGenerator` from a brick template.
/// {@endtemplate}
@JsonSerializable()
class BrickYaml {
  /// {@macro mason_yaml}
  const BrickYaml(
    this.name,
    this.description,
    this.vars,
  );

  /// Converts [Map] to [BrickYaml]
  factory BrickYaml.fromJson(Map<dynamic, dynamic> json) =>
      _$BrickYamlFromJson(json);

  /// Converts [BrickYaml] to [Map]
  Map<dynamic, dynamic> toJson() => _$BrickYamlToJson(this);

  /// static constant for brick configuration file name.
  /// `brick.yaml`
  static const file = 'brick.yaml';

  /// static constant for brick template directory name.
  /// `__brick__`
  static const dir = '__brick__';

  /// Name of the brick.
  final String name;

  /// Description of the brick.
  final String description;

  /// List of variables used when templating a brick.
  final List<String> vars;
}
