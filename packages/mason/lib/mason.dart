/// A Dart template generator which helps teams
/// generate files quickly and consistently.
///
/// Get started at [https://github.com/felangel/mason](https://github.com/felangel/mason) 🧱
library mason;

export 'package:mason_logger/mason_logger.dart';

export 'src/brick_yaml.dart' show BrickYaml;
export 'src/bricks_json.dart' show BricksJson;
export 'src/bundler.dart' show createBundle;
export 'src/exception.dart'
    show MasonException, BrickNotFoundException, WriteBrickException;
export 'src/generator.dart'
    show
        MasonGenerator,
        DirectoryGeneratorTarget,
        FileConflictResolution,
        TemplateFile;
export 'src/mason_bundle.dart' show MasonBundle;
export 'src/mason_yaml.dart' show Brick, GitPath, MasonYaml;
export 'src/render.dart' show RenderTemplate;
