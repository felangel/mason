import 'package:json_annotation/json_annotation.dart';
import 'package:masonex/masonex.dart';

part 'mason_lock_json.g.dart';

/// {@template masonex_lock_json}
/// Masonex lock file which contains locked brick locations.
/// {@endtemplate}
@JsonSerializable()
class MasonexLockJson {
  /// {@macro masonex_lock_json}
  const MasonexLockJson({Map<String, BrickLocation>? bricks})
      : bricks = bricks ?? const <String, BrickLocation>{};

  /// Converts [Map] to [MasonexLockJson]
  factory MasonexLockJson.fromJson(Map<dynamic, dynamic> json) =>
      _$MasonexLockJsonFromJson(json);

  /// Converts [MasonexLockJson] to [Map]
  Map<dynamic, dynamic> toJson() => _$MasonexLockJsonToJson(this);

  /// static constant for masonex lock file name.
  /// `masonex-lock.json`
  static const file = 'masonex-lock.json';

  /// static constant for an empty `masonex-lock.yaml` file.
  static const empty = MasonexLockJson();

  /// [Map] of [BrickLocation] alias to [BrickLocation] instances.
  final Map<String, BrickLocation> bricks;
}
