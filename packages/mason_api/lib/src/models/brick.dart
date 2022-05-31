import 'package:json_annotation/json_annotation.dart';

part 'brick.g.dart';

/// {@template brick}
/// Details of a brick from `brickhub.dev` registry
/// {@endtemplate}
@JsonSerializable()
class Brick {
  /// {@macro brick}
  const Brick({
    required this.name,
    required this.description,
    required this.version,
    required this.createdAt,
  });

  /// Converts a [Map] to [Brick].
  factory Brick.fromJson(Map<String, dynamic> json) => _$BrickFromJson(json);

  /// Name of the brick
  final String name;

  /// Description of the brick
  final String description;

  /// Latest registered version of the brick
  final String version;

  /// Date of the brick's creation
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Converts this [Brick] to `Map<String, dynamic>`.
  Map<String, dynamic> toJson() => _$BrickToJson(this);
}
