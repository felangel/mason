import 'dart:convert';

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
    this.vars = const <String, BrickVariableProperties>{},
    this.path,
    this.aliases,
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

  /// Map of variable properties used when templating a brick.
  @VarsConverter()
  final Map<String, BrickVariableProperties> vars;

  /// Path to the [BrickYaml] file.
  final String? path;

  /// Map of aliases to the values they represent.
  final Map<String, String>? aliases;

  /// Returns a copy of the current [BrickYaml] with
  /// an overridden [path].
  BrickYaml copyWith({String? path}) {
    return BrickYaml(
      name: name,
      description: description,
      version: version,
      vars: vars,
      path: path ?? this.path,
      aliases: aliases,
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

/// The type of brick variable.
enum BrickVariableType {
  /// A number (e.g. 42)
  number,

  /// A string (e.g. "Dash")
  string,

  /// A boolean (e.g. true/false)
  boolean,
}

/// {@template brick_variable_properties}
/// An object representing a brick variable.
/// {@endtemplate}
@immutable
@JsonSerializable()
class BrickVariableProperties {
  /// {@macro brick_variable_properties}
  @internal
  const BrickVariableProperties({
    required this.type,
    this.description,
    this.defaultValue,
    this.prompt,
  });

  /// {@macro brick_variable_properties}
  ///
  /// Creates an instance of a [BrickVariableProperties]
  /// of type [BrickVariableType.string].
  const BrickVariableProperties.string({
    String? description,
    String? defaultValue,
    String? prompt,
  }) : this(
          type: BrickVariableType.string,
          description: description,
          defaultValue: defaultValue,
          prompt: prompt,
        );

  /// {@macro brick_variable_properties}
  ///
  /// Creates an instance of a [BrickVariableProperties]
  /// of type [BrickVariableType.boolean].
  const BrickVariableProperties.boolean({
    String? description,
    bool? defaultValue,
    String? prompt,
  }) : this(
          type: BrickVariableType.boolean,
          description: description,
          defaultValue: defaultValue,
          prompt: prompt,
        );

  /// {@macro brick_variable_properties}
  ///
  /// Creates an instance of a [BrickVariableProperties]
  /// of type [BrickVariableType.number].
  const BrickVariableProperties.number({
    String? description,
    num? defaultValue,
    String? prompt,
  }) : this(
          type: BrickVariableType.number,
          description: description,
          defaultValue: defaultValue,
          prompt: prompt,
        );

  /// Converts [Map] to [BrickYaml]
  factory BrickVariableProperties.fromJson(Map<dynamic, dynamic> json) =>
      _$BrickVariablePropertiesFromJson(json);

  /// Converts [BrickVariableProperties] to [Map]
  Map<dynamic, dynamic> toJson() => _$BrickVariablePropertiesToJson(this);

  /// The type of the variable.
  final BrickVariableType type;

  /// An optional description of the variable.
  final String? description;

  /// An optional default value for the variable.
  @JsonKey(name: 'default')
  final Object? defaultValue;

  /// An optional prompt used when requesting the variable.
  final String? prompt;
}

/// {@template vars_converter}
/// Json Converter for [Map<String, BrickVariableProperties>].
/// {@endtemplate}
class VarsConverter
    implements JsonConverter<Map<String, BrickVariableProperties>, dynamic> {
  /// {@macro vars_converter}
  const VarsConverter();

  @override
  dynamic toJson(Map<String, BrickVariableProperties> value) {
    return value.map((key, value) => MapEntry(key, value.toJson()));
  }

  @override
  Map<String, BrickVariableProperties> fromJson(dynamic value) {
    final dynamic _value = value is String ? json.decode(value) : value;
    if (_value is List) {
      return <String, BrickVariableProperties>{
        for (final v in _value)
          v as String: const BrickVariableProperties.string(),
      };
    }
    if (_value is Map) {
      return _value.map(
        (dynamic key, dynamic value) => MapEntry(
          key as String,
          BrickVariableProperties.fromJson(_value[key] as Map),
        ),
      );
    }
    throw const FormatException();
  }
}
