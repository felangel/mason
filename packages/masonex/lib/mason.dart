/// A Dart template generator which helps teams
/// generate files quickly and consistently.
///
/// Get started at [https://github.com/felangel/masonex](https://github.com/felangel/masonex) 🧱
library masonex;

export 'package:masonex_logger/masonex_logger.dart';
export 'package:pub_semver/pub_semver.dart'
    show Version, VersionConstraint, VersionRange;

export 'src/brick.dart' show Brick;
export 'src/brick_compatibility.dart' show isBrickCompatibleWithMasonex;
export 'src/brick_yaml.dart'
    show
        BrickEnvironment,
        BrickVariableProperties,
        BrickVariableType,
        BrickYaml;
export 'src/bricks_json.dart' show BricksJson, CachedBrick;
export 'src/bundler.dart' show createBundle, unpackBundle;
export 'src/exception.dart' show BrickNotFoundException, MasonexException;
export 'src/generator.dart'
    show
        DirectoryGeneratorTarget,
        FileConflictResolution,
        GeneratedFile,
        GeneratedFileStatus,
        GeneratorHooks,
        GeneratorTarget,
        HookContext,
        MasonexGenerator,
        OverwriteRule,
        TemplateFile;
export 'src/masonex_bundle.dart' show MasonexBundle, MasonexBundledFile;
export 'src/masonex_lock_json.dart' show MasonexLockJson;
export 'src/masonex_yaml.dart' show BrickLocation, GitPath, MasonexYaml;
export 'src/path.dart' show canonicalize;
export 'src/render.dart' show RenderTemplate;
export 'src/string_case_extensions.dart' show StringCaseExtensions;
export 'src/version.dart' show packageVersion;
export 'src/yaml_encode.dart' show Yaml;
