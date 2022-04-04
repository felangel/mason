import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mason/src/brick_yaml.dart';
import 'package:mason/src/compute.dart';

part 'mason_bundle.g.dart';

/// {@template mason_bundled_file}
/// A bundled file which is included as part of a a [MasonBundle].
/// {@endtemplate}
@JsonSerializable()
class MasonBundledFile {
  /// {@macro mason_bundled_file}
  const MasonBundledFile(this.path, this.data, this.type);

  /// Converts a [Map<String, dynamic>] into a [MasonBundledFile].
  factory MasonBundledFile.fromJson(Map<String, dynamic> json) =>
      _$MasonBundledFileFromJson(json);

  /// The relative file path
  final String path;

  /// The encoded contents of the file
  final String data;

  /// The type of file (binary/text)
  final String type;

  /// Converts a [MasonBundledFile] into a [Map<String, dynamic>].
  Map<String, dynamic> toJson() => _$MasonBundledFileToJson(this);
}

/// {@template mason_bundle}
/// A bundled version of a mason template.
/// {@endtemplate}
@JsonSerializable()
class MasonBundle {
  /// {@macro mason_bundle}
  const MasonBundle({
    required this.name,
    required this.description,
    required this.version,
    this.environment = const BrickEnvironment(),
    this.vars = const <String, BrickVariableProperties>{},
    this.files = const [],
    this.hooks = const [],
    this.repository,
    this.readme,
    this.changelog,
    this.license,
  });

  /// Converts a [Map<String, dynamic>] into a [MasonBundle] instance.
  factory MasonBundle.fromJson(Map<String, dynamic> json) =>
      _$MasonBundleFromJson(json);

  /// Converts a universal bundle into a [MasonBundle] instance.
  static Future<MasonBundle> fromUniversalBundle(List<int> bytes) async {
    final bundleJson = await compute(
      (List<int> bytes) => json.decode(
        utf8.decode(BZip2Decoder().decodeBytes(bytes)),
      ) as Map<String, dynamic>,
      bytes,
    );
    return MasonBundle.fromJson(bundleJson);
  }

  /// Converts a dart bundle into a [MasonBundle] instance.
  static Future<MasonBundle> fromDartBundle(String content) async {
    final bundleJsonString = content.substring(
      content.indexOf('{'),
      content.lastIndexOf('}') + 1,
    );
    final bundleJson = await compute(
      (String jsonString) => json.decode(jsonString) as Map<String, dynamic>,
      bundleJsonString,
    );
    return MasonBundle.fromJson(bundleJson);
  }

  /// List of all [MasonBundledFile] instances within the `__brick__` directory.
  final List<MasonBundledFile> files;

  /// List of all [MasonBundledFile] instances within the `hooks` directory.
  final List<MasonBundledFile> hooks;

  /// Name of the brick (from the `brick.yaml`).
  final String name;

  /// Description of the brick (from the `brick.yaml`).
  final String description;

  /// The brick version (from the `brick.yaml`).
  final String version;

  /// The brick environment (from the `brick.yaml`).
  final BrickEnvironment environment;

  /// Optional url pointing to the brick's source code repository.
  final String? repository;

  /// The brick's README.md file.
  final MasonBundledFile? readme;

  /// The brick's CHANGELOG.md file.
  final MasonBundledFile? changelog;

  /// The brick's LICENSE file.
  final MasonBundledFile? license;

  /// All required variables for the brick (from the `brick.yaml`).
  @VarsConverter()
  final Map<String, BrickVariableProperties> vars;

  /// Converts a [MasonBundle] into a [Map<String, dynamic>].
  Map<String, dynamic> toJson() => _$MasonBundleToJson(this);

  /// Converts a [MasonBundle] into universal bundle bytes.
  Future<List<int>> toUniversalBundle() => compute(_encodeBundle, this);

  Future<List<int>> _encodeBundle(MasonBundle bundle) async {
    return BZip2Encoder().encode(utf8.encode(json.encode(bundle.toJson())));
  }
}
