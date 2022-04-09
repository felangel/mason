import 'package:json_annotation/json_annotation.dart';
import 'package:mason/mason.dart';

part 'mason_lock_json.g.dart';

/// {@template mason_lock_json}
/// Mason lock file which contains locked brick locations.
/// {@endtemplate}
@JsonSerializable()
class MasonLockJson {
  /// {@macro mason_lock}
  const MasonLockJson({Map<String, BrickLocation>? bricks})
      : bricks = bricks ?? const <String, BrickLocation>{};

  /// Converts [Map] to [MasonLockJson]
  factory MasonLockJson.fromJson(Map<dynamic, dynamic> json) =>
      _$MasonLockJsonFromJson(json);

  /// Converts [MasonLockJson] to [Map]
  Map<dynamic, dynamic> toJson() => _$MasonLockJsonToJson(this);

  /// static constant for mason lock file name.
  /// `mason-lock.json`
  static const file = 'mason-lock.json';

  /// static constant for an empty `mason-lock.yaml` file.
  static const empty = MasonLockJson();

  /// [Map] of [BrickLocation] alias to [BrickLocation] instances.
  final Map<String, BrickLocation> bricks;
}
