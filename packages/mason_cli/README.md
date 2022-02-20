<p align="center">
<img src="https://raw.githubusercontent.com/felangel/mason/master/assets/mason_full.png" height="125" alt="mason logo" />
</p>

<p align="center">
<a href="https://pub.dev/packages/mason_cli"><img src="https://img.shields.io/pub/v/mason_cli.svg" alt="Pub"></a>
<a href="https://github.com/felangel/mason/actions"><img src="https://github.com/felangel/mason/workflows/mason/badge.svg" alt="mason"></a>
<a href="https://github.com/felangel/mason/actions"><img src="https://raw.githubusercontent.com/felangel/mason/master/packages/mason_cli/coverage_badge.svg" alt="coverage"></a>
<a href="https://pub.dev/packages/very_good_analysis"><img src="https://img.shields.io/badge/style-very_good_analysis-B22C89.svg" alt="style: very good analysis"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

---

Mason CLI allows developers to create and consume reusable templates called bricks powered by the [mason](https://pub.dev/packages/mason) generator.

![Mason Demo][mason_demo]

## Quick Start

```sh
# 🎯 Activate from https://pub.dev
dart pub global activate mason_cli

# 🚀 Initialize mason
mason init

# 🧱 Use your first brick
mason make hello
```

---

## Table of Contents

- [Overview](#overview)
  - [Installation](#installation)
  - [Initializing](#initializing)
  - [Command Line Variables](#command-line-variables)
  - [Variable Prompts](#variable-prompts)
  - [Config File for Input Variables](#config-file-for-input-variables)
  - [Custom Output Directory](#custom-output-directory)
  - [File Conflict Resolution](#file-conflict-resolution)
- [Creating New Bricks](#creating-new-bricks)
  - [Brick YAML](#brick-yaml)
  - [Brick Template](#brick-template)
    - [Nested Templates (partials)](#nested-templates-partials)
    - [File Resolution](#file-resolution)
    - [Built-in Lambdas](#built-in-lambdas)
    - [Detecting Changes After Generation](#detecting-changes-after-generation)
    - [Custom Script Execution (Hooks)](#custom-script-execution-hooks)
      - [Hooks Usage](#hooks-usage)
- [Adding Bricks](#adding-bricks)
  - [Add Usage](#add-usage)
- [Removing Bricks](#removing-bricks)
  - [Remove Usage](#remove-usage)
- [List Installed Bricks](#list-installed-bricks)
  - [List Usage](#list-usage)
- [Bundling](#bundling)
  - [Bundle Usage](#bundle-usage)
- [Complete Usage](#complete-usage)
- [Video Tutorial](#video-tutorial)

## Overview

### Installation

```sh
# 🎯 Activate from https://pub.dev
dart pub global activate mason_cli

# 🍺 Or install from https://brew.sh
brew tap felangel/mason
brew install mason
```

### Initializing

```sh
mason init
```

`mason init` initializes the Mason CLI in the current directory.

Running `mason init` generates a `mason.yaml` and an example `brick` so that you can get started immediately.

```yaml
bricks:
  hello:
    path: bricks/hello
```

To get all bricks registered in `mason.yaml` run:

```sh
mason get
```

Then you can use `mason make` to generate your first file:

```sh
mason make hello
```

### Command Line Variables

Any variables can be passed as command line args.

```sh
mason make hello --name Felix
```

### Variable Prompts

Any variables which aren't specified as command line args will be prompted.

```sh
mason make hello
name: Felix
```

### Config File for Input Variables

Any variables can be passed via a config file:

```dart
mason make hello -c config.json
```

where `config.json` is:

```json
{
  "name": "Felix"
}
```

The above commands will all generate `HELLO.md` in the current directory with the following content:

```md
Hello Felix!
```

### Custom Output Directory

By default `mason make` will generate the template in the current working directory but a custom output directory can be specified via the `-o` option:

```sh
mason make hello --name Felix -o ./path/to/directory
```

### File Conflict Resolution

By default, `mason make` will prompt on each file conflict and will allow users to specify how the conflict should be resolved via `Yyna`:

```txt
y - yes, overwrite (default)
Y - yes, overwrite this and all others
n - no, do not overwrite
a - append to existing file
```

A custom file conflict resolution strategy can be specified via the `--on-conflict` option:

```sh
# Always prompt when there is a file conflict (default)
mason make hello --name Felix --on-conflict prompt

# Always overwrite when there is a file conflict
mason make hello --name Felix --on-conflict overwrite

# Always skip when there is a file conflict
mason make hello --name Felix --on-conflict skip

# Always append when there is a file conflict
mason make hello --name Felix --on-conflict append
```

## Creating New Bricks

Create a new brick using the `mason new` command.

```sh
mason new <BRICK_NAME>
```

The above command will generate a new brick in the `bricks` directory with a `brick.yaml` and `__brick__` template directory.

### Brick YAML

The `brick.yaml` contains metadata for a `brick` template.

```yaml
name: example
description: An example brick
version: 1.0.0
vars:
  name:
    type: string
    description: Your name.
    default: Dash
    prompt: What is your name?
```

### Brick Template

Write your brick template in the `__brick__` directory using [mustache templates](https://mustache.github.io/). See the [mustache manual](https://mustache.github.io/mustache.5.html) for detailed usage information.

`__brick__/example.md`

```md
# Hello {{name}}!
```

❗ **Note: `__brick__` can contain multiple files and subdirectories**

❗ **Note: use `{{{variable}}}` instead of `{{variable}}` when you want the value of `variable` to be unescaped**

#### Nested Templates (partials)

It is possible to have templates nested within other templates. For example, given the follow structure:

```
├── HELLO.md
├── {{~ footer.md }}
└── {{~ header.md }}
```

The `{{~ header.md }}` and `{{~ footer.md }}` are partials (partial brick templates). Partials will not be generated but can be included as part of an existing template.

For example given the contents of `{{~ header.md }}` and `{{~ footer.md }}` respectively

```md
# 🧱 {{name}}
```

```md
_made with 💖 by mason_
```

we can include the partials as part of a template via `{{> header.md }}` and `{{> footer.md }}`.

In this example, given `HELLO.md`:

```md
{{> header.md }}

Hello {{name}}!

{{> footer.md }}
```

We can use `mason make hello --name Felix` to generate `HELLO.md`:

```md
# 🧱 Felix

Hello Felix!

_made with 💖 by mason_
```

❗ **Note: Partials can contain variables just like regular templates**

#### File Resolution

It is possible to resolve files based on path input variables using the `{{% %}}` tag.

For example, given the following `brick.yaml`:

```yaml
name: app_icon
description: Create an app icon file from a URL
version: 0.1.0+1
vars:
  url:
    type: string
    description: The app icon URL.
    prompt: Enter your app icon URL.
```

And the following brick template:

`__brick__/{{% url %}}`

Running `mason make app_icon --url path/to/icon.png` will generate `icon.png` with the contents of `path/to/icon.png` where the `path/to/icon.png` can be either a local or remote path. Check out the [app icon example brick](bricks/app_icon) to try it out.

#### Built-in Lambdas

Mason supports a handful of built-in lambdas that can help with customizing generated code:

| Name           | Example       | Usage                                            |
| -------------- | ------------- | ------------------------------------------------ |
| `camelCase`    | `helloWorld`  | `{{#camelCase}}{{variable}}{{/camelCase}}`       |
| `constantCase` | `HELLO_WORLD` | `{{#constantCase}}{{variable}}{{/constantCase}}` |
| `dotCase`      | `hello.world` | `{{#dotCase}}{{variable}}{{/dotCase}}`           |
| `headerCase`   | `Hello-World` | `{{#headerCase}}{{variable}}{{/headerCase}}`     |
| `lowerCase`    | `hello world` | `{{#lowerCase}}{{variable}}{{/lowerCase}}`       |
| `pascalCase`   | `HelloWorld`  | `{{#pascalCase}}{{variable}}{{/pascalCase}}`     |
| `paramCase`    | `hello-world` | `{{#paramCase}}{{variable}}{{/paramCase}}`       |
| `pathCase`     | `hello/world` | `{{#pathCase}}{{variable}}{{/pathCase}}`         |
| `sentenceCase` | `Hello world` | `{{#sentenceCase}}{{variable}}{{/sentenceCase}}` |
| `snakeCase`    | `hello_world` | `{{#snakeCase}}{{variable}}{{/snakeCase}}`       |
| `titleCase`    | `Hello World` | `{{#titleCase}}{{variable}}{{/titleCase}}`       |
| `upperCase`    | `HELLO WORLD` | `{{#upperCase}}{{variable}}{{/upperCase}}`       |

_Example Usage_

Given the following example brick:

```
__brick__
  ├── {{#snakeCase}}{{name}}{{/snakeCase}}.md
  └── {{#pascalCase}}{{name}}{{/pascalCase}}.java
```

`brick.yaml`:

```yaml
name: example
description: An example brick.
version: 0.1.0+1
vars:
  name:
    type: string
    description: Your name
    default: Dash
    prompt: What is your name?
```

We can generate code via:

```sh
mason make example --name my-name
```

The output will be:

```
├── my_name.md
└── MyName.java
```

#### Detecting Changes After Generation

Mason supports verifying that `mason make` did not change any files via the `--set-exit-if-changed` flag. This is often useful in continuous integration (CI) environments to ensure all generated code is up to date.

```sh
# fail with exit code 70 if any files were changed
mason make example --name Dash --set-exit-if-changed
```

#### Custom Script Execution (Hooks)

Mason supports custom script execution via `hooks`. The supported hooks are:

- `pre_gen` - executed immediately before the generation step
- `post_gen` - executed immediately after the generation step

Hooks must be defined in the `hooks` directory at the root of the brick:

```
├── __brick__
├── brick.yaml
└── hooks
    ├── post_gen.dart
    ├── pre_gen.dart
    └── pubspec.yaml
```

❗ Currently mason only supports hooks written in [Dart](https://dart.dev).

##### Hooks Usage

Every hook must contain a `run` method which accepts a `HookContext` from `package:mason/mason.dart`.

For example, given the following `example` brick:

```sh
.
├── __brick__
│   └── example.md
├── brick.yaml
└── hooks
    ├── post_gen.dart
    └── pubspec.yaml
```

where `brick.yaml` looks like:

```yaml
name: example
description: An example brick.
version: 0.1.0+1
vars:
  name:
    type: string
    description: Your name
    default: Dash
    prompt: What is your name?
```

and `pubspec.yaml` looks like:

```yaml
name: example_hooks

environment:
  sdk: ">=2.12.0 <3.0.0"

dependencies:
  mason: any
```

And `post_gen.dart` contains:

```dart
import 'package:mason/mason.dart';

void run(HookContext context) {
  context.logger.info('hello {{name}}!');
}
```

The result of running `mason make example --name Dash` would be:

```sh
mason make example --name Dash
✓ Made brick example (0.0s)
✓ Generated 1 file:
  /Users/dash/mason/example/example.md (new)
hello Dash!
```

💡 **Note**: Scripts can contain template variables. In addition, the working directory of the script is the directory in which the code is generated.

`HookContext` can be used to access/modify the brick `vars` or to interface with the logger.

```dart
import 'package:mason/mason.dart';

void run(HookContext context) {
  // Read/Write vars
  context.vars = {...context.vars, 'custom_var': 'foo'};

  // Use the logger
  context.logger.info('hook says hi!');
}
```

Hook execution can be disabled using the `--no-hooks` flag:

```sh
# Disable hook script execution
mason make example --name Dash --no-hooks
```

## Adding Bricks

The `add` command allows developers to add brick templates locally or globally on their machines from either a local path or git url. By default `mason add` will add the template locally but bricks can be added globally by providing the `--global` (`-g`) flag.

### Add Usage

```sh
# add from registry
mason add my_brick

# add from registry (global)
mason add --global my_brick

# add from registry shorthand syntax (global)
mason add -g my_brick

# add from path
mason add my_brick --path ./path/to/my_brick

# add from path (global)
mason add --global my_brick --path ./path/to/my_brick

# add from path shorthand syntax (global)
mason add -g my_brick --path ./path/to/my_brick

# add from git url
mason add my_brick --git-url https://github.com/org/repo

# add from git url (global)
mason add -g my_brick --git-url https://github.com/org/repo

# add from git url with path
mason add my_brick --git-url https://github.com/org/repo --git-path path/to/my_brick

# add from git url with path and ref
mason add my_brick --git-url https://github.com/org/repo --git-path path/to/my_brick --git-ref tag-name
```

Once a brick is added it can be used via the `mason make` command:

```sh
mason make <BRICK_NAME>
```

## Removing Bricks

Bricks can be removed by using the `remove` command. Use the `--global` (`-g`) flag to remove global bricks.

### Remove Usage

```sh
# remove brick
mason remove <BRICK_NAME>

# remove brick (global)
mason remove -g <BRICK_NAME>
```

## List Installed Bricks

All installed bricks can be seen via the `list` (`ls` for short) command.

### List Usage

```sh
# list all locally installed bricks
mason list

# list all globally installed bricks
mason list --global

# use alias "ls" instead of "list" for a shorthand syntax
mason ls

# list all globally installed bricks shorthand syntax
mason ls -g
```

## Bundling

You can use mason to generate a bundle for an existing template. Bundles are convenient for cases where you want to include your template as part of a standalone CLI. [Very Good CLI](https://github.com/VeryGoodOpenSource/very_good_cli) is a great example.

There are currently two types of bundles:

1. Universal - a platform-agnostic bundle
2. Dart - a Dart specific bundle

### Bundle Usage

To generate a bundle:

```sh
# Universal Bundle
mason bundle ./path/to/brick -o ./path/to/destination

# Dart Bundle
mason bundle ./path/to/brick -t dart -o ./path/to/destination
```

A bundle can then be used to generate code from a brick programmatically:

```dart
// Create a MasonGenerator from the existing bundle.
final generator = MasonGenerator.fromBundle(...);

// Generate code based on the bundled brick.
await generator.generate(...);
```

## Complete Usage

```sh
mason
🧱  mason • lay the foundation!

Usage: mason <command> [arguments]

Global options:
-h, --help       Print this usage information.
    --version    Print the current version.

Available commands:
  add       Adds a brick from a local or remote source.
  bundle    Generates a bundle from a brick template.
  cache     Interact with mason cache.
  get       Gets all bricks in the nearest mason.yaml.
  init      Initialize mason in the current directory.
  list      Lists installed bricks.
  login     Log into brickhub.dev.
  logout    Log out of brickhub.dev.
  make      Generate code using an existing brick template.
  new       Creates a new brick template.
  publish   Publish the current brick to brickhub.dev.
  remove    Removes a brick.
  update    Update mason.

Run "mason help <command>" for more information about a command.
```

## Video Tutorial

[![Mason Video Tutorial](https://img.youtube.com/vi/SnrHoN632NU/0.jpg)](https://www.youtube.com/watch?v=SnrHoN632NU)

**Say HI to Mason Package! - The Top Tier Code Generation Tool | Complete Tutorial** by [_Flutterly_](https://www.youtube.com/channel/UC5PYcSe3to4mtm3SPCUmjvw)

[mason_demo]: https://raw.githubusercontent.com/felangel/mason/master/assets/mason_demo.gif
