import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'brick_yaml.g.dart';

/// {@template mason_yaml}
/// Brick yaml file which contains metadata required to create
/// a `MasonGenerator` from a brick template.
/// {@endtemplate}
@immutable
@JsonSerializable()
class BrickYaml {
  /// {@macro mason_yaml}
  const BrickYaml({
    required this.name,
    required this.description,
    required this.version,
    this.vars = const <String>[],
    this.path,
  });

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

  /// static constant for brick hooks directory name.
  /// `hooks`
  static const hooks = 'hooks';

  /// Name of the brick.
  final String name;

  /// Description of the brick.
  final String description;

  /// Version of the brick (semver).
  final String version;

  /// List of variables used when templating a brick.
  final List<String> vars;

  /// Path to the [BrickYaml] file.
  final String? path;

  /// Returns a copy of the current [BrickYaml] with
  /// an overridden [path].
  BrickYaml copyWith({String? path}) {
    return BrickYaml(
      name: name,
      description: description,
      version: version,
      vars: vars,
      path: path ?? this.path,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrickYaml && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
