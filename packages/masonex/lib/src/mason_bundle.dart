import 'dart:convert';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:masonex/src/brick_yaml.dart';

part 'mason_bundle.g.dart';

/// {@template masonex_bundled_file}
/// A bundled file which is included as part of a a [MasonexBundle].
/// {@endtemplate}
@JsonSerializable()
class MasonexBundledFile {
  /// {@macro masonex_bundled_file}
  const MasonexBundledFile(this.path, this.data, this.type);

  /// Converts a [Map<String, dynamic>] into a [MasonexBundledFile].
  factory MasonexBundledFile.fromJson(Map<String, dynamic> json) =>
      _$MasonexBundledFileFromJson(json);

  /// The relative file path
  final String path;

  /// The encoded contents of the file
  final String data;

  /// The type of file (binary/text)
  final String type;

  /// Converts a [MasonexBundledFile] into a [Map<String, dynamic>].
  Map<String, dynamic> toJson() => _$MasonexBundledFileToJson(this);
}

/// {@template masonex_bundle}
/// A bundled version of a masonex template.
/// {@endtemplate}
@JsonSerializable(fieldRename: FieldRename.snake)
class MasonexBundle {
  /// {@macro masonex_bundle}
  const MasonexBundle({
    required this.name,
    required this.description,
    required this.version,
    this.environment = const BrickEnvironment(),
    this.vars = const <String, BrickVariableProperties>{},
    this.files = const [],
    this.hooks = const [],
    this.repository,
    this.publishTo,
    this.readme,
    this.changelog,
    this.license,
  });

  /// Converts a [Map<String, dynamic>] into a [MasonexBundle] instance.
  factory MasonexBundle.fromJson(Map<String, dynamic> json) =>
      _$MasonexBundleFromJson(json);

  /// Converts a universal bundle into a [MasonexBundle] instance.
  static Future<MasonexBundle> fromUniversalBundle(List<int> bytes) async {
    final bundleJson = await Isolate.run(
      () => json.decode(
        utf8.decode(BZip2Decoder().decodeBytes(bytes)),
      ) as Map<String, dynamic>,
    );
    return MasonexBundle.fromJson(bundleJson);
  }

  /// Converts a dart bundle into a [MasonexBundle] instance.
  static Future<MasonexBundle> fromDartBundle(String content) async {
    final bundleJsonString = content.substring(
      content.indexOf('{'),
      content.lastIndexOf('}') + 1,
    );
    final bundleJson = await Isolate.run(
      () => json.decode(bundleJsonString) as Map<String, dynamic>,
    );
    return MasonexBundle.fromJson(bundleJson);
  }

  /// List of all [MasonexBundledFile] instances within the `__brick__` directory.
  final List<MasonexBundledFile> files;

  /// List of all [MasonexBundledFile] instances within the `hooks` directory.
  final List<MasonexBundledFile> hooks;

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

  /// Optional url used to specify a custom brick registry
  /// as the publish target.
  final String? publishTo;

  /// The brick's README.md file.
  final MasonexBundledFile? readme;

  /// The brick's CHANGELOG.md file.
  final MasonexBundledFile? changelog;

  /// The brick's LICENSE file.
  final MasonexBundledFile? license;

  /// All required variables for the brick (from the `brick.yaml`).
  @VarsConverter()
  final Map<String, BrickVariableProperties> vars;

  /// Converts a [MasonexBundle] into a [Map<String, dynamic>].
  Map<String, dynamic> toJson() => _$MasonexBundleToJson(this);

  /// Converts a [MasonexBundle] into universal bundle bytes.
  Future<List<int>> toUniversalBundle() {
    return Isolate.run(() => _encodeBundle(this));
  }

  Future<List<int>> _encodeBundle(MasonexBundle bundle) async {
    return BZip2Encoder().encode(utf8.encode(json.encode(bundle.toJson())));
  }
}
