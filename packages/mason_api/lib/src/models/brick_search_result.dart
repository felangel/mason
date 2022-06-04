import 'package:json_annotation/json_annotation.dart';

part 'brick_search_result.g.dart';

/// {@template brick_search_result}
/// Brick search result details from brickhub.dev.
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
    required this.downloads,
  });

  /// Converts a [Map] to [BrickSearchResult].
  factory BrickSearchResult.fromJson(Map<String, dynamic> json) =>
      _$BrickSearchResultFromJson(json);

  /// The name of the brick.
  final String name;

  /// The brick description.
  final String description;

  /// The email of the brick publisher.
  final String publisher;

  /// The latest published version of the brick.
  final String version;

  /// The date when the brick was created.
  final DateTime createdAt;

  /// The number of times the brick has been downloaded.
  final int downloads;
}
