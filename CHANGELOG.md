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
