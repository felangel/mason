import 'package:json_annotation/json_annotation.dart';
import 'package:mason/src/brick_yaml.dart';

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
  const MasonBundle(
    this.name,
    this.description,
    this.version,
    this.vars,
    this.files,
    this.hooks,
  );

  /// Converts a [Map<String, dynamic>] into a [MasonBundle] instance.
  factory MasonBundle.fromJson(Map<String, dynamic> json) =>
      _$MasonBundleFromJson(json);

  /// List of all [MasonBundledFile] instances within the `__brick__` directory.
  final List<MasonBundledFile> files;

  /// List of all [MasonBundledFile] instances within the `hooks` directory.
  @JsonKey(defaultValue: <MasonBundledFile>[])
  final List<MasonBundledFile> hooks;

  /// Name of the brick (from the `brick.yaml`).
  final String name;

  /// Description of the brick (from the `brick.yaml`).
  final String description;

  /// The brick version (from the `brick.yaml`).
  final String version;

  /// All required variables for the brick (from the `brick.yaml`).
  @VarsConverter()
  final Map<String, BrickVariableProperties> vars;

  /// Converts a [MasonBundle] into a [Map<String, dynamic>].
  Map<String, dynamic> toJson() => _$MasonBundleToJson(this);
}
