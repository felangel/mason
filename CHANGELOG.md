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
