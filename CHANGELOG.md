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
