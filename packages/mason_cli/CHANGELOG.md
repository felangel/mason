# 0.1.0-dev.40

- feat: add `hooks/build` to `.gitignore` when generating new brick
- deps: upgrade to `mason: ^0.1.0-dev.39`

# 0.1.0-dev.39

- perf: compile bricks
- deps: upgrade to `mason: ^0.1.0-dev.38`

# 0.1.0-dev.38

- deps: upgrade to `mason: ^0.1.0-dev.35`

# 0.1.0-dev.37

- feat: support `mason upgrade -g`
- deps: upgrade to `mason: ^0.1.0-dev.34`
- deps: upgrade to `mason_api: ^0.1.0-dev.8`
- deps: upgrade to `pub_updater: ^0.2.2`

# 0.1.0-dev.36

- feat: support `mason add <brick> <version>`

# 0.1.0-dev.35

- fix: `upgrade` from subdirectory w/relative paths
- fix: `add` from subdirectory w/relative path
- feat: use logger `link` api

# 0.1.0-dev.34

- fix: call `close` on `MasonApi` client

# 0.1.0-dev.33

- feat: disable lints in Dart bundles
- docs: add additional metadata to `pubspec.yaml`

# 0.1.0-dev.32

- refactor(deps): remove `pkg:universal_io`
- feat: upgrade to `mason_api: ^0.1.0-dev.6`
- feat: upgrade to `mason: ^0.1.0-dev.30`
  - includes `mason_logger: ^0.1.1`

# 0.1.0-dev.31

- feat: upgrade to `mason: ^0.1.0-dev.29`
  - includes `mason_logger: ^0.1.0`

# 0.1.0-dev.30

- feat: support bundling git and hosted bricks

  ```sh
  # Create a bundle from a git brick.
  mason bundle --source git https://github.com/:org/:repo

  # Create a bundle from a hosted brick.
  mason bundle --source hosted <BRICK_NAME>
  ```

# 0.1.0-dev.29

- feat: support array vars in `brick.yaml`
- feat: bump minimum mason version in new bricks

# 0.1.0-dev.28

- feat: support enum vars in `brick.yaml`

# 0.1.0-dev.27

- feat: add `mason search` command
- feat: improve usage exceptions

# 0.1.0-dev.26

- feat: upgrade to `mason: ^0.1.0-dev.23`
  - includes `mason_logger: ^0.1.0-dev.9`

# 0.1.0-dev.25

- feat: add `mason upgrade` command to upgrade bricks to their latest versions

# 0.1.0-dev.24

- fix: add link to mason badge in new brick READMEs

# 0.1.0-dev.23

- feat: add mason badge to new bricks

  ```md
  ![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)
  ```

# 0.1.0-dev.22

- feat: upgrade to `mason: ^0.1.0-dev.15`

# 0.1.0-dev.21

- feat: add `--hooks` flag to `mason new` command

# 0.1.0-dev.20

- fix: `mason add` fix progress logging typo

# 0.1.0-dev.19

- docs: add note regarding `.mason` and `mason-lock.json`
- chore: upgrade to `mason 0.1.0-dev.14`
- chore: add policy details on publish

# 0.1.0-dev.18

- feat: generate `mason-lock.json` to lock brick versions

# 0.1.0-dev.17

- chore: use fixed version of `hello` brick in `mason init`

# 0.1.0-dev.16

- feat: upgrade to `mason_api ^v0.1.0-dev.4`
  - improve error messages for `mason publish`

# 0.1.0-dev.15

- **BREAKING**: feat: `mason new` only generates new brick w/custom output-dir
- feat: `mason init` only generate `mason.yaml`
- feat: `mason new` adjust generated file name
- feat: `mason new` add inline comments `brick.yaml`
- feat: `mason new` include `README`, `CHANGELOG`, and `LICENSE`

# 0.1.0-dev.14

- feat: add `mason unbundle` command
- chore: upgrade to `mason ^0.1.0-dev.10`

# 0.1.0-dev.13

- feat: improve stdout for `mason bundle`
- fix: mason list git path parsing

# 0.1.0-dev.12

- feat: support for environment in `brick.yaml`
  - `mason init` includes `environment`
  - `mason new` includes `environment`
- feat: verify brick compatibility
  - `mason get` ensures bricks are compatible
  - `mason add` ensures bricks are compatible
  - `mason make` ensures bricks are compatible

# 0.1.0-dev.11

- **BREAKING**: feat: `mason add` support for hosted bricks

  ```sh
  # add from registry
  mason add my_brick
  ```

- feat: `mason login` command
- feat: `mason logout` command
- feat: `mason publish` command
- feat: `mason list` includes brick source
- fix: clear `bricks.json` prior to fetching via `mason get`
- fix: verify/validate brick name matches name in `mason.yaml` during `mason get`
- fix: simplify update prompt styling
- refactor: populate bricks from `bricks.json` directly
- refactor: remove dependency on `package:archive`
- docs: update `README` to include new commands
- chore: upgrade to `mason ^0.1.0-dev.7`
- chore: upgrade to Dart 2.16

# 0.1.0-dev.10

- **BREAKING** feat: upgrade to `mason ^0.1.0-dev.6`

  - add `--set-exit-if-changed` to `make` command

    ```sh
    # fail with exit code 70 if any files were changed
    mason make greeting --name Dash --set-exit-if-changed
    ✓ Made brick greeting (0.1s)
    ✓ Generated 1 file:
      GREETINGS.md (new)
    ✗ 1 file changed
    ```

# 0.1.0-dev.9

- feat: apply bzip compression to universal bundle
- chore: fix typo in CHANGELOG

# 0.1.0-dev.8

- feat: add `mason update` command
- feat: remove auto-update prompt when newer version exists
- docs: minor updates to CLI description and README

# 0.1.0-dev.7

- **BREAKING** feat: upgrade to `mason ^0.1.0-dev.5`

  - computed vars support via `HookContext`

    ```dart
    // pre_gen.dart
    import 'package:mason/mason.dart';

    // Every hook must contain a run method which accepts a `HookContext`
    // from package:mason/mason.dart.
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

- **BREAKING** feat: upgrade to `mason ^0.1.0-dev.4`
  - `version` is required in `MasonBundle`
  - `brick.yaml` variable enhancement support
- feat: `mason make <brick> --help` variable enhancements
  - show variable types, descriptions, and default values
- feat: enhance bricks generated by:
  - `mason init`
  - `mason new`
- feat: `mason ls` returns bricks in alphabetical order

# 0.1.0-dev.5

- **BREAKING** feat: upgrade to `mason ^0.1.0-dev.3`
  - `version` is required in `brick.yaml`
- feat: add `version` to newly created bricks
  - `mason new` and `mason init`

# 0.1.0-dev.4

- chore: upgrade to `mason ^0.1.0-dev.2`

# 0.1.0-dev.3

- feat: add `mason list --global` ([#176](https://github.com/felangel/mason/pull/176))
- chore(deps): upgrade to `build_verify: ^3.0.0`

# 0.1.0-dev.2

- feat: upgrade to `mason ^0.1.0-dev.1`

# 0.1.0-dev.1

**Dev Release**

- chore: initial package (🚧 under construction 🚧)
