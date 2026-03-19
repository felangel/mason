# 0.1.3

- feat: include allowed values in `masonex make <name> --help`
- ci: upgrade runners to `windows-latest`

# 0.1.2

- feat: improve the output of `masonex --version` ([#1482](https://github.com/felangel/masonex/issues/1482))
  ```sh
  $ masonex --version
  masonex_cli 0.1.1 • command-line interface
  masonex 0.1.0 • core templating engine
  ```

# 0.1.1

- fix: `masonex init` uses `hello 0.1.0+2` for `masonex v0.1.0` compatibility

# 0.1.0

- chore: bump to stable v0.1.0 🎉

# 0.1.0-dev.57

- feat: `masonex add` prompt to overwrite on conflict ([#1435](https://github.com/felangel/masonex/issues/1435))

# 0.1.0-dev.56

- deps: tighten dependency constraints ([#1403](https://github.com/felangel/masonex/issues/1403))
  - bumps the Dart SDK minimum version up to `3.5.0`
- chore: add `funding` to `pubspec.yaml` ([#1371](https://github.com/felangel/masonex/issues/1371))
- docs: document non top level partials ([#1355](https://github.com/felangel/masonex/issues/1355))

# 0.1.0-dev.55

- deps: upgrade to `masonex 0.1.0-dev.53` and `masonex_logger v0.2.15`
  - bump minimum Dart SDK to 3.3.0
- deps: upgrade to `cli_completion 0.5.0`

# 0.1.0-dev.54

- feat: add `--set-exit-if-changed` to `masonex bundle` ([#1229](https://github.com/felangel/masonex/issues/1229))
- chore(deps): upgrade dependencies

# 0.1.0-dev.53

- feat: add `--watch` to `masonex make` ([#1131](https://github.com/felangel/masonex/issues/1131))

# 0.1.0-dev.52

- upgrade to `masonex 0.1.0-dev.51` and `masonex_logger v0.2.9`
  - fix: arrow keys on windows ([#816](https://github.com/felangel/masonex/issues/816))
- chore: improve lint rules
- chore: `dart fix --apply`
- chore(deps): upgrade dependencies

# 0.1.0-dev.51

- feat: support for type `list` in `brick.yaml` vars
  ```yaml
  vars:
    languages:
      type: list
      description: Your favorite languages
      prompt: What are your favorite languages?
  ```

# 0.1.0-dev.50

- feat: standardize stdout across commands
- feat: `masonex init` does not automatically install the "hello" brick
- feat: `masonex init` enhancements to the comments in the generated `masonex.yaml`

# 0.1.0-dev.49

- fix: loop detection in `runSubstitution`
  - deps: upgrade to `masonex ^0.1.0-dev.47`
- feat: `masonex new` updates existing brick
- refactor: streamline stdout from `masonex bundle`
- refactor: `masonex add` uses "build" instead of "compile"

# 0.1.0-dev.48

- feat: add `--force` and `--dry-run` to `publish` command

# 0.1.0-dev.47

- feat: add `repository` field and `README` updates to new brick
- feat: support `publish_to` field in `brick.yaml`
- deps: upgrade to `masonex ^0.1.0-dev.46`

# 0.1.0-dev.46

- fix: brick git installation algorithm
- deps: upgrade to `masonex ^0.1.0-dev.43`

# 0.1.0-dev.45

- feat: add `--quiet` flag to `make` command
- deps: upgrade dependencies
  - `Dart >=2.19`
  - `masonex ^0.1.0-dev.42`
  - `masonex_api ^0.1.0-dev.10`
  - `very_good_analysis ^4.0.0`

# 0.1.0-dev.44

- fix: silent update failures

# 0.1.0-dev.43

- deps: upgrade dependencies
  - `Dart >=2.17`
  - `cli_completion ^0.2.0`
  - `masonex ^0.1.0-dev.41`
  - `masonex_api ^0.1.0-dev.9`
  - `very_good_analysis ^3.1.0`

# 0.1.0-dev.42

- deps: upgrade to `masonex: ^0.1.0-dev.40`
- feat: masonex search separator length uses `terminalColumns`
- feat: improve error when running `masonex add` in an uninitialized workspace

# 0.1.0-dev.41

- feat: add completion

# 0.1.0-dev.40

- feat: add `hooks/build` to `.gitignore` when generating new brick
- deps: upgrade to `masonex: ^0.1.0-dev.39`

# 0.1.0-dev.39

- perf: compile bricks
- deps: upgrade to `masonex: ^0.1.0-dev.38`

# 0.1.0-dev.38

- deps: upgrade to `masonex: ^0.1.0-dev.35`

# 0.1.0-dev.37

- feat: support `masonex upgrade -g`
- deps: upgrade to `masonex: ^0.1.0-dev.34`
- deps: upgrade to `masonex_api: ^0.1.0-dev.8`
- deps: upgrade to `pub_updater: ^0.2.2`

# 0.1.0-dev.36

- feat: support `masonex add <brick> <version>`

# 0.1.0-dev.35

- fix: `upgrade` from subdirectory w/relative paths
- fix: `add` from subdirectory w/relative path
- feat: use logger `link` api

# 0.1.0-dev.34

- fix: call `close` on `MasonexApi` client

# 0.1.0-dev.33

- feat: disable lints in Dart bundles
- docs: add additional metadata to `pubspec.yaml`

# 0.1.0-dev.32

- refactor(deps): remove `pkg:universal_io`
- feat: upgrade to `masonex_api: ^0.1.0-dev.6`
- feat: upgrade to `masonex: ^0.1.0-dev.30`
  - includes `masonex_logger: ^0.1.1`

# 0.1.0-dev.31

- feat: upgrade to `masonex: ^0.1.0-dev.29`
  - includes `masonex_logger: ^0.1.0`

# 0.1.0-dev.30

- feat: support bundling git and hosted bricks

  ```sh
  # Create a bundle from a git brick.
  masonex bundle --source git https://github.com/:org/:repo

  # Create a bundle from a hosted brick.
  masonex bundle --source hosted <BRICK_NAME>
  ```

# 0.1.0-dev.29

- feat: support array vars in `brick.yaml`
- feat: bump minimum masonex version in new bricks

# 0.1.0-dev.28

- feat: support enum vars in `brick.yaml`

# 0.1.0-dev.27

- feat: add `masonex search` command
- feat: improve usage exceptions

# 0.1.0-dev.26

- feat: upgrade to `masonex: ^0.1.0-dev.23`
  - includes `masonex_logger: ^0.1.0-dev.9`

# 0.1.0-dev.25

- feat: add `masonex upgrade` command to upgrade bricks to their latest versions

# 0.1.0-dev.24

- fix: add link to masonex badge in new brick READMEs

# 0.1.0-dev.23

- feat: add masonex badge to new bricks

  ```md
  ![Powered by Masonex](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmasonex-badge)
  ```

# 0.1.0-dev.22

- feat: upgrade to `masonex: ^0.1.0-dev.15`

# 0.1.0-dev.21

- feat: add `--hooks` flag to `masonex new` command

# 0.1.0-dev.20

- fix: `masonex add` fix progress logging typo

# 0.1.0-dev.19

- docs: add note regarding `.masonex` and `masonex-lock.json`
- chore: upgrade to `masonex 0.1.0-dev.14`
- chore: add policy details on publish

# 0.1.0-dev.18

- feat: generate `masonex-lock.json` to lock brick versions

# 0.1.0-dev.17

- chore: use fixed version of `hello` brick in `masonex init`

# 0.1.0-dev.16

- feat: upgrade to `masonex_api ^v0.1.0-dev.4`
  - improve error messages for `masonex publish`

# 0.1.0-dev.15

- **BREAKING**: feat: `masonex new` only generates new brick w/custom output-dir
- feat: `masonex init` only generate `masonex.yaml`
- feat: `masonex new` adjust generated file name
- feat: `masonex new` add inline comments `brick.yaml`
- feat: `masonex new` include `README`, `CHANGELOG`, and `LICENSE`

# 0.1.0-dev.14

- feat: add `masonex unbundle` command
- chore: upgrade to `masonex ^0.1.0-dev.10`

# 0.1.0-dev.13

- feat: improve stdout for `masonex bundle`
- fix: masonex list git path parsing

# 0.1.0-dev.12

- feat: support for environment in `brick.yaml`
  - `masonex init` includes `environment`
  - `masonex new` includes `environment`
- feat: verify brick compatibility
  - `masonex get` ensures bricks are compatible
  - `masonex add` ensures bricks are compatible
  - `masonex make` ensures bricks are compatible

# 0.1.0-dev.11

- **BREAKING**: feat: `masonex add` support for hosted bricks

  ```sh
  # add from registry
  masonex add my_brick
  ```

- feat: `masonex login` command
- feat: `masonex logout` command
- feat: `masonex publish` command
- feat: `masonex list` includes brick source
- fix: clear `bricks.json` prior to fetching via `masonex get`
- fix: verify/validate brick name matches name in `masonex.yaml` during `masonex get`
- fix: simplify update prompt styling
- refactor: populate bricks from `bricks.json` directly
- refactor: remove dependency on `package:archive`
- docs: update `README` to include new commands
- chore: upgrade to `masonex ^0.1.0-dev.7`
- chore: upgrade to Dart 2.16

# 0.1.0-dev.10

- **BREAKING** feat: upgrade to `masonex ^0.1.0-dev.6`

  - add `--set-exit-if-changed` to `make` command

    ```sh
    # fail with exit code 70 if any files were changed
    masonex make greeting --name Dash --set-exit-if-changed
    ✓ Made brick greeting (0.1s)
    ✓ Generated 1 file:
      GREETINGS.md (new)
    ✗ 1 file changed
    ```

# 0.1.0-dev.9

- feat: apply bzip compression to universal bundle
- chore: fix typo in CHANGELOG

# 0.1.0-dev.8

- feat: add `masonex update` command
- feat: remove auto-update prompt when newer version exists
- docs: minor updates to CLI description and README

# 0.1.0-dev.7

- **BREAKING** feat: upgrade to `masonex ^0.1.0-dev.5`

  - computed vars support via `HookContext`

    ```dart
    // pre_gen.dart
    import 'package:masonex/masonex.dart';

    // Every hook must contain a run method which accepts a `HookContext`
    // from package:masonex/masonex.dart.
    void run(HookContext context) {
      // Read / Write vars
      context.vars = {
        ...context.vars,
        'custom_var': 'foo',
      };

      // Use the logger
      context.logger.info('hello from pre_gen.dart');
    }
    ```

# 0.1.0-dev.6

- **BREAKING** feat: upgrade to `masonex ^0.1.0-dev.4`
  - `version` is required in `MasonexBundle`
  - `brick.yaml` variable enhancement support
- feat: `masonex make <brick> --help` variable enhancements
  - show variable types, descriptions, and default values
- feat: enhance bricks generated by:
  - `masonex init`
  - `masonex new`
- feat: `masonex ls` returns bricks in alphabetical order

# 0.1.0-dev.5

- **BREAKING** feat: upgrade to `masonex ^0.1.0-dev.3`
  - `version` is required in `brick.yaml`
- feat: add `version` to newly created bricks
  - `masonex new` and `masonex init`

# 0.1.0-dev.4

- chore: upgrade to `masonex ^0.1.0-dev.2`

# 0.1.0-dev.3

- feat: add `masonex list --global` ([#176](https://github.com/felangel/masonex/pull/176))
- chore(deps): upgrade to `build_verify: ^3.0.0`

# 0.1.0-dev.2

- feat: upgrade to `masonex ^0.1.0-dev.1`

# 0.1.0-dev.1

**Dev Release**

- chore: initial package (🚧 under construction 🚧)
