# 0.1.10

- feat: support mason new brick
- deps: dependency updates

# 0.1.9

- feat: add support for `publish_to` field in `brick.yaml`
- deps: various dependency updates

# 0.1.8

- fix: support spaces in mason make `--output-dir`

# 0.1.7

- fix: `mason.yaml` git url schema validation
  - support other formats such as `ssh`

# 0.1.6

- feat: YAML schema validation for `mason.yaml`
- feat: YAML schema validation for `brick.yaml`

# 0.1.5

- fix: enum defaults to first value when no default specified

# 0.1.4

- fix: make command supports spaces in string variables

# 0.1.3

- fix: activate make commands when extension is initialized

# 0.1.2

- feat: add commands
  - Mason: Make Local Brick
  - Mason: Make Global Brick

# 0.1.1

- feat: add commands
  - Mason: Init
  - Mason: Add Local Brick
  - Mason: Add Global Brick
  - Mason: Remove Local Brick
  - Mason: Remove Global Brick

# 0.1.0

- feat: initial release
  - detect missing mason installation
  - automatically run `mason get` when `mason.yaml` is saved.
