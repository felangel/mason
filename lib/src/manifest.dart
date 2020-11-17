import 'package:json_annotation/json_annotation.dart';

part 'manifest.g.dart';

/// {@template manifest}
/// Mason manifest yaml file which contains metadata required to create
/// a `MasonGenerator`.
/// {@endtemplate}
@JsonSerializable()
class Manifest {
  /// {@macro manifest}
  const Manifest(this.name, this.description, this.files, this.args);

  /// Converts [Map] to [Manifest]
  factory Manifest.fromJson(Map<dynamic, dynamic> json) =>
      _$ManifestFromJson(json);

  /// Converts [Manifest] to [Map]
  Map<dynamic, dynamic> toJson() => _$ManifestToJson(this);

  /// Name of the `MasonGenerator`
  final String name;

  /// Description of the `MasonGenerator`
  final String description;

  /// List of [TemplateFile] which are used to seed the `MasonGenerator`
  final List<TemplateFile> files;

  /// List of args needed when templating `MasonGenerator`
  final List<String> args;
}

/// {@template template_file}
/// A Template File which consists of the path to the template
/// and the destination path (relative to the current working directory).
/// {@endtemplate}
@JsonSerializable()
class TemplateFile {
  /// {@macro template_file}
  const TemplateFile(this.from, this.to);

  /// Converts [Map] to [TemplateFile]
  factory TemplateFile.fromJson(Map<dynamic, dynamic> json) =>
      _$TemplateFileFromJson(json);

  /// The path to the template file.
  final String from;

  /// The relative path where the generated file should be created.
  final String to;

  /// Converts [TemplateFile] to [Map]
  Map<dynamic, dynamic> toJson() => _$TemplateFileToJson(this);
}
