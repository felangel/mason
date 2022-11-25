# 0.1.0-dev.39

- **BREAKING** refactor!: remove `GeneratorHooks.fromBundle` in favor of `GeneratorHooks.fromBrickYaml`.
- feat: support relative imports in hooks
- feat: support non-ascii characters in hooks
- feat: support bricks with no `__brick__` directory
- feat: hook artifacts are stored in the `build/hooks` directory within the corresponding hooks directory
- feat: bundled artifacts from `MasonGenerator.fromBundle` are stored in the `bundled` directory within the mason cache.
- fix: avoid bundling extraneous hook files (e.g. coverage files)

# 0.1.0-dev.38

- perf: compile hooks
- fix: allow optional `__brick__` directory

# 0.1.0-dev.37

- fix: hook execution after pub cache clean

# 0.1.0-dev.36

- fix: support mp3 binary file types

# 0.1.0-dev.35

- **BREAKING** feat!: avoid templating hook contents
- chore(deps): upgrade to `mason_logger ^0.2.2`

# 0.1.0-dev.34

- chore(deps): upgrade to `mason_logger ^0.2.0`

# 0.1.0-dev.33

- refactor: use `mason_logger ^0.1.3`

# 0.1.0-dev.32

- fix: use file descriptor pooling
- chore: add additional `pubspec.yaml` metadata

# 0.1.0-dev.31

- fix: render asymmetrical shorthand lambda expressions correctly

# 0.1.0-dev.30

- refactor(deps): remove `pkg:universal_io`
- refactor: use `mason_logger ^0.1.1`

# 0.1.0-dev.29

- fix: improve lambda shorthand syntax flexibility
- perf: speed up hooks execution
- refactor: use `mason_logger ^0.1.0`

# 0.1.0-dev.28

- fix: override `toString` on `MasonException`

# 0.1.0-dev.27

- perf: run substitutions in isolate and improve render specificity
- chore: use `mason_logger ^0.1.0-dev.14`

# 0.1.0-dev.26

- fix: file path looping array resolution
- feat: `brick.yaml` vars array support

  ```yaml
  vars:
    color:
      type: array
      description: Your desired build flavors
      defaults:
        - production
      prompt: What build flavors would you like?
      values:
        - development
        - staging
        - production
  ```

# 0.1.0-dev.25

- fix: do not prompt when overwrite rule is `alwaysOverwrite`
- feat: `brick.yaml` vars enum support

  ```yaml
  vars:
    color:
      type: enum
      description: Your favorite color
      default: green
      prompt: What is your favorite color?
      values:
        - red
        - green
        - blue
  ```

# 0.1.0-dev.24

- fix: rendering shorthand lambdas within loops

# 0.1.0-dev.23

- chore: use `mason_logger ^0.1.0-dev.9`

# 0.1.0-dev.22

- feat: add `mustacheCase` lambda

# 0.1.0-dev.21

- feat: expose `OverwriteRule`

# 0.1.0-dev.20

- feat: expose `GeneratorTarget`

# 0.1.0-dev.19

- refactor: improve brick location serialization for hosted bricks

  ```yaml
  # before
  hello:
    version: ^0.1.0

  # after
  hello: ^0.1.0
  ```

# 0.1.0-dev.18

- fix: `HookContext` vars mutation

# 0.1.0-dev.17

- fix: lambda shorthand conditional interop
- fix: lambda shorthand partials interop

# 0.1.0-dev.16

- fix: lamdba shorthand syntax interop

# 0.1.0-dev.15

- feat: introduce shorthand lambda syntax
  - `{{name.upperCase()}}` <-> `{{#upperCase}}{{name}}{{/upperCase}}`
- chore: use `mason_logger ^0.1.0-dev.8`

# 0.1.0-dev.14

- feat: add optional `repository` field to `brick.yaml`

# 0.1.0-dev.13

- **BREAKING**: feat: `BricksJson.add` returns `CachedBrick` instead of `String` location.
- feat: add `MasonLockJson`
- feat: export `CachedBrick`, `GeneratorHooks`, `MasonLockJson`, `Version`, `VersionConstraint`, and `VersionRange`

# 0.1.0-dev.12

- feat: include `README`, `CHANGELOG`, and `LICENSE` in `MasonBundle`

# 0.1.0-dev.11

- fix: `Yaml.encode` handle escape characters

# 0.1.0-dev.10

- **BREAKING**: feat: run `fromUniversalBundle` in `Isolate` (async)
- feat: expose `Yaml` encoding utility
- feat: add `fromDartBundle` to `MasonBundle`

# 0.1.0-dev.9

- feat: expose `MasonBundledFile`

# 0.1.0-dev.8

- feat: add environment to `brick.yaml`

  ```yaml
  name: example
  description: An example brick
  version: 0.1.0+1

  environment:
    mason: ">=0.1.0-dev.1 <0.1.0"
  ```

- feat: add `isBrickCompatibleWithMason`

# 0.1.0-dev.7

- **BREAKING**: feat: add `MasonGenerator.fromBrick`
  - refactor: remove `MasonGenerator.fromGitPath` (use `fromBrick` instead)
  - refactor: remove `MasonGenerator.fromBrickYaml` (use `fromBrick` instead)
- **BREAKING**: refactor: `Brick` named constructors
  - `Brick.path`, `Brick.git`, `Brick.version`
- **BREAKING**: refactor: remove `WriteBrickException`
- **BREAKING**: refactor: simplify `bricks.json` format
- refactor: git cache directory location
- feat: add `fromUniversalBundle` and `toUniversalBundle` on `MasonBundle`
- feat: add `BrickLocation`
- feat: add `unpackBundle` to convert universal bundle bytes to a `MasonBundle`
- fix: yaml string encoding for semver
- fix: `BrickNotFoundException` message when git path is empty
- chore: upgrade to `mason_logger ^0.1.0-dev.5`
- chore: upgrade to Dart 2.16

# 0.1.0-dev.6

- **BREAKING** feat: return list of `GeneratedFile` from `generate`

```dart
import 'dart:io';

import 'package:mason/mason.dart';

Future<void> main() async {
  final generator = await MasonGenerator.fromGitPath(
    const GitPath(
      'https://github.com/felangel/mason.git',
      path: 'bricks/greeting',
    ),
  );
  final files = await generator.generate(
    DirectoryGeneratorTarget(Directory.current),
    vars: <String, dynamic>{'name': 'Dash'},
  );
}
```

- feat: expose `packageVersion`

# 0.1.0-dev.5

- **BREAKING** feat: add computed vars support via `HookContext`

```dart
// pre_gen.dart

import 'package:mason/mason.dart';

// Every hook must contain a run method which accepts a `HookContext`
// from package:mason/mason.dart.
void run(HookContext context) {
  // Read/Write vars
  context.vars = {...context.vars, 'custom_var': 'foo'};

  // Use the logger
  context.logger.info('hello from pre_gen.dart');
}
```

# 0.1.0-dev.4

- **BREAKING** feat: restructure `brick.yaml` vars to support type, description, and default:

```yaml
name: example
description: An example brick.

# The following defines the version and build number for your brick.
# A version number is three numbers separated by dots, like 1.2.34
# followed by an optional build number (separated by a +).
version: 0.1.0+1

# Variables specify dynamic values that your brick depends on.
# Zero or more variables can be specified for a given brick.
# Each variable has:
#  * a type (string, number, or boolean)
#  * an optional short description
#  * an optional default value
#  * an optional prompt phrase used when asking for the variable.
vars:
  name:
    type: string
    description: Your name
    default: Dash
    prompt: What is your name?
```

- **BREAKING** feat: add `version` to bundle
- **BREAKING** refactor: API improvements to `MasonBundle`, `MasonGenerator`, and `DirectoryGeneratorTarget`

  - `MasonBundle`
    - Use named constructor parameters instead of positional parameters
  - `MasonGenerator.generate(...)`
    - Accepts optional `Logger` and `FileConflictResolution`
  - `DirectoryGeneratorTarget`
    - No longer accepts optional `Logger` and `FileConflictResolution` (moved to `generate` API above)

  **Before**

  ```dart
  final generator = MasonGenerator.fromBundle(myBundle);
  final target = DirectoryGeneratorTarget(dir, Logger(), FileConflictResolution.skip);
  await generator.generate(target, vars: {...});
  ```

  **After**

  ```dart
  final generator = MasonGenerator.fromBundle(myBundle);
  final target = DirectoryGeneratorTarget(dir);
  await generator.generate(
    DirectoryGeneratorTarget(tempDir),
    vars: {...},
    logger: Logger(), // optional logger
    fileConflictResolution: FileConflictResolution.skip, // optional conflict resolution strategy
  );
  ```

- fix: ignore `FileConflictResolution` when there are no conflicts
- docs: README updates and upgrade example bricks
- chore: upgrade to `mason_logger: v0.1.0-dev.4`

# 0.1.0-dev.3

- **BREAKING** feat: add version to `brick.yaml`
- fix: bundle file sort order

# 0.1.0-dev.2

- feat: export `render` APIs
  - `RenderTemplate` extension on `String`

# 0.1.0-dev.1

- feat: decompose `mason` into `mason`, `mason_cli` and `mason_logger`
  - `package:mason` - core generator
  - `package:mason_cli` - command line interface
  - `package:mason_logger` - reusable logger
- fix: file resolution with custom path generates in the correct location

# 0.0.1-dev.57

- feat: add `mason bundle` output
- feat: add generator hooks support (custom script execution)
  - support for `pre_gen` and `post_gen` hooks

# 0.0.1-dev.56

- fix: `mason new` output format improvements
  - use `logger.detail` instead of `logger.success` color for consistency

# 0.0.1-dev.55

- fix: partials file name resolution

# 0.0.1-dev.54

- fix: nested lambdas within loops

# 0.0.1-dev.53

- feat: improve automatic update prompt style

# 0.0.1-dev.52

- feat: add automatic update support

# 0.0.1-dev.51

- feat: conditional file and directory creation support

# 0.0.1-dev.50

- **BREAKING** refactor: remove `mason install` and `mason uninstall`
  - `mason install` -> `mason add -g`
  - `mason uninstall` -> `mason remove -g`
- feat: adjust `mason init` generated `mason.yaml`
- feat: improve `mason list` empty output
- feat: create `mason remove` command
- feat: create `mason add` command
- feat: `mason init` command automatically gets first brick
- feat: improve output and description for `mason get` command
- fix: logger stopwatch units
- docs: update example/README

# 0.0.1-dev.49

- refactor: remove `dart:io` platform dependency

# 0.0.1-dev.48

- feat: add append conflict resolution strategy
- fix: mason get ensures brick exists
- docs: add built-in lambdas section to README

# 0.0.1-dev.47

- fix: `vars` in `brick.yaml` are not required

# 0.0.1-dev.46

- fix: `mason bundle` resolves `implicit_dynamic_map_literal` in generated Dart bundle
- docs: add bundle usage to README

# 0.0.1-dev.45

- fix: `mason bundle` add `.otf` support

# 0.0.1-dev.44

- feat: custom file conflict resolution via `mason make --on-conflict`

# 0.0.1-dev.43

- feat: support partials

  Example:

  ```
  ├── HELLO.md
  ├── {{~ footer.md }}
  └── {{~ header.md }}
  ```

  `{{~ header.md }}`

  ```md
  # 🧱 {{name}}
  ```

  `{{~ footer.md }}`

  ```md
  _made with 💖 by mason_
  ```

  `HELLO.md`

  ```md
  {{> header.md }}

  Hello {{name}}!

  {{> footer.md }}
  ```

  `$ mason make hello --name Dash`

  `HELLO.md`

  ```md
  # 🧱 Dash

  Hello Dash!

  _made with 💖 by mason_
  ```

# 0.0.1-dev.42

- fix: improve `mason make --help` to show complete usage information

  ```sh
  Generate code using an existing brick template.

  Usage: mason make [arguments]
  -h, --help           Print this usage information.
  -c, --config-path    Path to config json file containing variables.
  -o, --output-dir     Directory where to output the generated code.
                      (defaults to ".")

  Run "mason help" to see global options.
  ```

# 0.0.1-dev.41

- feat: add `OverwriteRule` for file conflict resolution (`Yna`)
  - `Y` - overwrite (default)
  - `n` - do not overwrite
  - `a` - overwrite this and all others

# 0.0.1-dev.40

- fix: create target directory if it does not exist

# 0.0.1-dev.39

- feat!: update `mason make` to support custom output directory via `--output-dir` (`-o`)
- refactor!: rename `mason bundle --directory` (`-d`) to `mason bundle --output-dir` (`-o`)
- refactor!: rename `mason make --json` (`-j`) to `mason make --config-path` (`-c`)

# 0.0.1-dev.38

- feat!: remove `--force` from `mason cache clear`
  - `mason cache clear` will remove all local bricks so `--force` is not necessary
- fix: `mason cache clear` behavior to always clear local and global brick caches
- fix: local and global brick installation conflicts
- fix: `mason list` duplicate bricks
- refactor: `MasonCache` to `BricksJson`
  - simplification of internal APIs and cache implementation

# 0.0.1-dev.37

- feat: add `mason list` command
- docs: update command descriptions for consistency

# 0.0.1-dev.36

- feat: add `mason uninstall` command

# 0.0.1-dev.35

- fix: adjust `mason cache clear --force` target directory to avoid deleting local files

# 0.0.1-dev.34

- fix: local mason get installation location for remote bricks
- fix!: always attempt to fetch latest remote brick
  - `mason get` no longer supports `--force` since it is handled automatically

# 0.0.1-dev.33

- feat: mason install command for global brick templates
- docs: update mustache manual link
- docs: update mason.yaml from init to use https for git

# 0.0.1-dev.32

- feat!: windows compatibility fixes
  - 100% compatibility across macos, linux, and windows
  - if you are experiencing issues after upgrading, try force re-fetching all templates via `mason get --force`

# 0.0.1-dev.31

- feat: new templates are readily available
- docs: update README usage section to include `bundle`
- docs: update file resolution section and include note about unescaped variables

# 0.0.1-dev.30

- fix: improved error handling and error reporting
  - improve error message when `mason new` is missing a brick name
  - improve error message when `mason make` is missing a subcommand
  - `mason get` handle empty brick list in `mason.yaml`
  - avoid hydrating cache when `bricks.json` is empty.
- docs: add bundling documentation to `README`

# 0.0.1-dev.29

- refactor: update logger api to support nullable strings

# 0.0.1-dev.28

- **BREAKING** feat: migrate to null safety
- **BREAKING** refactor: update file resolution tag to `{{% %}}` for windows compatibility
- fix: normalize brick paths to avoid escaping issues on windows

# 0.0.1-dev.27

- fix: `mason bundle` path resolution fixes

# 0.0.1-dev.26

- feat: exclude analyzer warnings from dart bundle

# 0.0.1-dev.25

- feat: add `mason bundle` command
- feat: add `MasonGenerator.fromBundle`
- fix: asset resolution issues

# 0.0.1-dev.24

- feat: add `mason cache clear` command
- fix: `mason get` restores bricks when `brick.json` is empty/missing

# 0.0.1-dev.23

- fix: support non-ascii characters in templates

# 0.0.1-dev.22

- fix: issue with variable mutation which excluded variables within arrays

# 0.0.1-dev.21

- feat: export `MasonGenerator` and relevant objects to allow `mason` to be consumed as a library
- feat: expose `fromGitPath` on `MasonGenerator`

# 0.0.1-dev.20

- fix: file loop content template variable resolution

# 0.0.1-dev.19

- feat: file loop support
- fix: mason init incorrectly throwing MissingMasonYamlException
- refactor: simplify MasonGenerator.fromBrickYaml

# 0.0.1-dev.18

- **BREAKING** revert: remove dart executable template support
- feat: add `lowerCase` and `upperCase` lambdas
- fix: support non utf8 encoded files
- fix: switch templating engine to be lenient by default
- refactor: avoid templating content with no delimeters

# 0.0.1-dev.17

- feat: support dart execution inside templates
- docs: add random_number example
- fix: handle empty or missing vars in `brick.yaml`

# 0.0.1-dev.16

- **BREAKING**: `mason make` creates subcommands for all available bricks
  - `mason make <BRICK_NAME> -- --var1 value1 --var2 value2` -> `mason make <BRICK_NAME> --var1 value1 --var2 value2`
- feat: `mason make -h` provides a list of available subcommands based on available bricks
- feat: add `mason get` to get all bricks
- feat: support for `mason get --force`
- feat: add local cache all bricks
- feat: improve error handling and messaging
- feat: require brick name consistency between `mason.yaml` and `brick.yaml`
- fix: handle empty or malformed `mason.yaml`
- fix: handle empty or malformed `brick.yaml`

# 0.0.1-dev.15

- feat: add `mason new` to create a new brick
- feat: `mason init` sets up bricks with sample
- fix: support bricks without `vars`
- fix: support bricks with empty `vars`
- docs: revamp README to include `Quick Start` section

# 0.0.1-dev.14

- fix: mason init path resolution

# 0.0.1-dev.13

- feat: improve `mason init` output
- refactor: internal brick improvements
- refactor: internal configuration file renaming

# 0.0.1-dev.12

- feat: add `mason init`
- feat: improve CLI output and error messages
- docs: update README documentation

# 0.0.1-dev.11

- **BREAKING**: rename `templates` to `bricks`
  - rename `__template__` to `__brick__`
  - rename `template.yaml` to `brick.yaml`
- **BREAKING**: rename `mason build` to `mason make`

# 0.0.1-dev.10

- feat: support file resolution from path variable

# 0.0.1-dev.9

- fix: unhandled `json` exception when `--json` omitted

# 0.0.1-dev.8

- feat: support for `--json` option in `mason build`
- feat: support loops in templates

# 0.0.1-dev.7

- **BREAKING** `mason.yaml` is required
- **BREAKING** template yaml no longer has files
- **BREAKING** `mason.yaml` format changed
  - all template files and directories should be included inside `__template__`
- feat: `mason.yaml` format changed
- feat: nearest `mason.yaml` will be used
- fix: improved error handling
- docs: `README` updates

# 0.0.1-dev.6

- feat: support `mason.yaml`
- feat: support prompts for vars
- refactor: use `CommandRunner`
- docs: `README` updates

# 0.0.1-dev.5

- fix: stop progress on build error

# 0.0.1-dev.4

- fix: mason CLI version fix

# 0.0.1-dev.3

- feat: support for remote templates
- feat: CLI loading indicator

# 0.0.1-dev.2

- docs: inline documentation updates

# 0.0.1-dev.1

**Dev Release**

- feat: `mason build` command with custom template
- feat: mustache template support
- feat: built-in recase lambdas
