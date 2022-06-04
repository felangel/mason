import 'package:json_annotation/json_annotation.dart';

part 'brick_search_result.g.dart';

/// {@template brick_search_result}
/// Details of a brick from `brickhub.dev` registry
/// {@endtemplate}
@JsonSerializable(createToJson: false)
class BrickSearchResult {
  /// {@macro brick_search_result}
  const BrickSearchResult({
    required this.name,
    required this.description,
    required this.publisher,
    required this.version,
    required this.createdAt,
  });

  /// Converts a [Map] to [BrickSearchResult].
  factory BrickSearchResult.fromJson(Map<String, dynamic> json) =>
      _$BrickSearchResultFromJson(json);

  /// Name of the brick
  final String name;

  /// Description of the brick
  final String description;

  /// Description of the brick
  final String publisher;

  /// Latest registered version of the brick
  final String version;

  /// Date of the brick's creation
  final DateTime createdAt;
}
