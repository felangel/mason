/// A Dart template generator which helps teams
/// generate files quickly and consistently.
///
/// Get started at [https://github.com/felangel/mason](https://github.com/felangel/mason) 🧱
library mason;

export 'package:mason_logger/mason_logger.dart';
export 'package:pub_semver/pub_semver.dart'
    show Version, VersionConstraint, VersionRange;

export 'src/brick.dart' show Brick;
export 'src/brick_compatibility.dart' show isBrickCompatibleWithMason;
export 'src/brick_yaml.dart'
    show
        BrickYaml,
        BrickEnvironment,
        BrickVariableProperties,
        BrickVariableType;
export 'src/bricks_json.dart' show BricksJson, CachedBrick;
export 'src/bundler.dart' show createBundle, unpackBundle;
export 'src/exception.dart' show BrickNotFoundException, MasonException;
export 'src/generator.dart'
    show
        DirectoryGeneratorTarget,
        FileConflictResolution,
        GeneratedFile,
        GeneratedFileStatus,
        GeneratorHooks,
        GeneratorTarget,
        HookContext,
        MasonGenerator,
        OverwriteRule,
        TemplateFile;
export 'src/mason_bundle.dart' show MasonBundle, MasonBundledFile;
export 'src/mason_lock_json.dart' show MasonLockJson;
export 'src/mason_yaml.dart' show BrickLocation, GitPath, MasonYaml;
export 'src/path.dart' show canonicalize;
export 'src/render.dart' show RenderTemplate;
export 'src/version.dart' show packageVersion;
export 'src/yaml_encode.dart' show Yaml;
