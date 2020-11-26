import 'package:json_annotation/json_annotation.dart';

part 'manifest.g.dart';

/// {@template manifest}
/// Mason manifest yaml file which contains metadata required to create
/// a `MasonGenerator`.
/// {@endtemplate}
@JsonSerializable()
class Manifest {
  /// {@macro manifest}
  const Manifest(
    this.name,
    this.description,
    this.vars, {
    String brick,
  }) : brick = brick ?? '__brick__';

  /// Converts [Map] to [Manifest]
  factory Manifest.fromJson(Map<dynamic, dynamic> json) =>
      _$ManifestFromJson(json);

  /// Converts [Manifest] to [Map]
  Map<dynamic, dynamic> toJson() => _$ManifestToJson(this);

  /// Name of the `MasonGenerator`
  final String name;

  /// Description of the `MasonGenerator`
  final String description;

  /// Optional path to brick directory.
  /// Defaults to `__brick__`.
  final String brick;

  /// List of variables used when templating `MasonGenerator`
  final List<String> vars;
}
