part of 'generator.dart';

/// {@template mason_generator}
/// A [MasonGenerator] which extends [Generator] and
/// exposes the ability to create a [Generator] from a
/// [Brick].
/// {@endtemplate}
class MasonGenerator extends Generator {
  /// {@macro mason_generator}
  MasonGenerator(
    String id,
    String description, {
    List<TemplateFile?> files = const <TemplateFile>[],
    GeneratorHooks hooks = const GeneratorHooks(),
    this.vars = const <String>[],
  }) : super(id, description, hooks) {
    for (final file in files) {
      addTemplateFile(file);
    }
  }

  /// Factory which creates a [MasonGenerator] based on
  /// a configuration file for a [BrickYaml]:
  ///
  /// ```yaml
  /// name: greetings
  /// description: A Simple Greetings Template
  /// vars:
  ///   - name
  /// ```
  static Future<MasonGenerator> fromBrickYaml(BrickYaml brick) async {
    final brickRoot = File(brick.path!).parent.path;
    final brickDirectory = p.join(brickRoot, BrickYaml.dir);
    final brickFiles = Directory(brickDirectory)
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) {
      return () async {
        try {
          final content = await File(file.path).readAsBytes();
          final relativePath = file.path.substring(
            file.path.indexOf(BrickYaml.dir) + 1 + BrickYaml.dir.length,
          );
          return TemplateFile.fromBytes(relativePath, content);
        } on Exception {
          return null;
        }
      }();
    });

    return MasonGenerator(
      brick.name,
      brick.description,
      vars: brick.vars.keys.toList(),
      files: await Future.wait(brickFiles),
      hooks: await GeneratorHooks.fromBrickYaml(brick),
    );
  }

  /// Factory which creates a [MasonGenerator] based on
  /// a local [MasonBundle].
  static Future<MasonGenerator> fromBundle(MasonBundle bundle) async {
    return MasonGenerator(
      bundle.name,
      bundle.description,
      vars: bundle.vars.keys.toList(),
      files: _decodeConcatenatedData(bundle.files),
      hooks: GeneratorHooks.fromBundle(bundle),
    );
  }

  /// Factory which creates a [MasonGenerator] based on
  /// a [GitPath] for a remote [BrickYaml] file.
  static Future<MasonGenerator> fromGitPath(GitPath gitPath) async {
    final directory = await BricksJson.temp().add(Brick(git: gitPath));
    final file = File(p.join(directory, gitPath.path, BrickYaml.file));
    final brickYaml = checkedYamlDecode(
      file.readAsStringSync(),
      (m) => BrickYaml.fromJson(m!),
    ).copyWith(path: file.path);
    return MasonGenerator.fromBrickYaml(brickYaml);
  }

  /// Optional list of variables which will be used to populate
  /// the corresponding mustache variables within the template.
  final List<String> vars;
}
