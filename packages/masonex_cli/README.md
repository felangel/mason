<p align="center">
<img src="https://raw.githubusercontent.com/felangel/masonex/master/assets/masonex_full.png" height="125" alt="masonex logo" />
</p>

<p align="center">
<a href="https://pub.dev/packages/masonex_cli"><img src="https://img.shields.io/pub/v/masonex_cli.svg" alt="Pub"></a>
<a href="https://github.com/felangel/masonex/actions"><img src="https://github.com/felangel/masonex/workflows/masonex_cli/badge.svg" alt="masonex"></a>
<a href="https://github.com/felangel/masonex/actions"><img src="https://raw.githubusercontent.com/felangel/masonex/master/packages/masonex_cli/coverage_badge.svg" alt="coverage"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
<a href="https://github.com/felangel/masonex"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmasonex-badge" alt="Powered by Masonex"></a>
</p>

---

[![en](https://img.shields.io/badge/language-english-cyan.svg)](https://github.com/felangel/masonex/blob/master/packages/masonex_cli/README.md)
[![zh](https://img.shields.io/badge/language-chinese-cyan.svg)](https://github.com/felangel/masonex/blob/master/packages/masonex_cli/README.zh.md)

Masonex CLI allows developers to create and consume reusable templates called bricks powered by the [masonex](https://pub.dev/packages/masonex) generator.

![Masonex Demo][masonex_demo]

## Quick Start

```sh
# 🎯 Activate from https://pub.dev
dart pub global activate masonex_cli

# 🚀 Initialize masonex
masonex init

# 📦 Install your first brick
masonex add hello

# 🧱 Use your first brick
masonex make hello
```

---

## Table of Contents

- [Quick Start](#quick-start)
- [Table of Contents](#table-of-contents)
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
- [Searching for Bricks](#searching-for-bricks)
  - [Search Usage](#search-usage)
- [Adding Bricks](#adding-bricks)
  - [Add Usage](#add-usage)
- [Removing Bricks](#removing-bricks)
  - [Remove Usage](#remove-usage)
- [List Installed Bricks](#list-installed-bricks)
  - [List Usage](#list-usage)
- [Upgrade Bricks](#upgrade-bricks)
  - [Upgrade Usage](#upgrade-usage)
- [Bundling](#bundling)
  - [Bundle Usage](#bundle-usage)
- [Unbundling](#unbundling)
  - [Unbundle Usage](#unbundle-usage)
- [Login](#login)
  - [Login Usage](#login-usage)
- [Logout](#logout)
  - [Logout Usage](#logout-usage)
- [Publishing Bricks](#publishing-bricks)
  - [Publish Usage](#publish-usage)
- [Complete Usage](#complete-usage)
- [Video Tutorial](#video-tutorial)

## Overview

### Installation

```sh
# 🎯 Activate from https://pub.dev
dart pub global activate masonex_cli

# 🍺 Or install from https://brew.sh
brew tap felangel/masonex
brew install masonex
```

### Initializing

```sh
masonex init
```

`masonex init` initializes the Masonex CLI in the current directory.

Running `masonex init` generates a `masonex.yaml` so that you can get started immediately.

```yaml
# Register bricks which can be consumed via the Masonex CLI.
# Run "masonex get" to install all registered bricks.
# To learn more, visit https://docs.brickhub.dev.
bricks:
  # Bricks can be imported via version constraint from a registry.
  # Uncomment the following line to import the "hello" brick from BrickHub.
  # hello: 0.1.0+2
  # Bricks can also be imported via remote git url.
  # Uncomment the following lines to import the "widget" brick from git.
  # widget:
  #   git:
  #     url: https://github.com/felangel/masonex.git
  #     path: bricks/widget
```

For example, we can uncomment the "hello" brick (`hello: 0.1.0+1`):

```yaml
bricks:
  hello: 0.1.0+1
```

Next, get all bricks registered in `masonex.yaml` via:

```sh
masonex get
```

Then you can use `masonex make` to generate your first file:

```sh
masonex make hello
```

❗ Note: **DO NOT** commit the `.masonex` directory. **DO** commit the `masonex-lock.json` file when working with versioned bricks (git/hosted).

### Command Line Variables

Any variables can be passed as command line args.

```sh
masonex make hello --name Felix
```

### Variable Prompts

Any variables which aren't specified as command line args will be prompted.

```sh
masonex make hello
name: Felix
```

### Config File for Input Variables

Any variables can be passed via a config file:

```dart
masonex make hello -c config.json
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

By default `masonex make` will generate the template in the current working directory but a custom output directory can be specified via the `-o` option:

```sh
masonex make hello --name Felix -o ./path/to/directory
```

### File Conflict Resolution

By default, `masonex make` will prompt on each file conflict and will allow users to specify how the conflict should be resolved via `Yyna`:

```txt
y - yes, overwrite (default)
Y - yes, overwrite this and all others
n - no, do not overwrite
a - append to existing file
```

A custom file conflict resolution strategy can be specified via the `--on-conflict` option:

```sh
# Always prompt when there is a file conflict (default)
masonex make hello --name Felix --on-conflict prompt

# Always overwrite when there is a file conflict
masonex make hello --name Felix --on-conflict overwrite

# Always skip when there is a file conflict
masonex make hello --name Felix --on-conflict skip

# Always append when there is a file conflict
masonex make hello --name Felix --on-conflict append
```

## Creating New Bricks

Create a new brick using the `masonex new` command.

```sh
# Generate a new brick in the current directory.
masonex new <BRICK_NAME>

# Generate a new brick with a custom description.
masonex new <BRICK_NAME> --desc "My awesome, new brick!"

# Generate a new brick with hooks.
masonex new <BRICK_NAME> --hooks

# Generate a new brick in custom path.
masonex new <BRICK_NAME> --output-dir ./path/to/brick

# Generate a new brick in custom path shorthand syntax.
masonex new <BRICK_NAME> -o ./path/to/brick
```

### Brick YAML

The `brick.yaml` contains metadata for a `brick` template.

```yaml
name: example
description: An example brick

# The following defines the version and build number for your brick.
# A version number is three numbers separated by dots, like 1.2.34
# followed by an optional build number (separated by a +).
version: 0.1.0+1

# The following defines the environment for the current brick.
# It includes the version of masonex that the brick requires.
environment:
  masonex: ^0.1.0

# Variables specify dynamic values that your brick depends on.
# Zero or more variables can be specified for a given brick.
# Each variable has:
#  * a type (string, number, boolean, enum, array, or list)
#  * an optional short description
#  * an optional default value
#  * an optional list of default values (array only)
#  * an optional prompt phrase used when asking for the variable
#  * a list of values (enums only)
#  * an optional separator (list only)
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

❗ **Note: Partials must always be directly under the `__brick__` directory. Non-top-level partials are [yet to be
supported](https://github.com/felangel/masonex/issues/378).**

For example given the contents of `{{~ header.md }}` and `{{~ footer.md }}` respectively

```md
# 🧱 {{name}}
```

```md
_made with 💖 by masonex_
```

we can include the partials as part of a template via `{{> header.md }}` and `{{> footer.md }}`.

In this example, given `HELLO.md`:

```md
{{> header.md }}

Hello {{name}}!

{{> footer.md }}
```

We can use `masonex make hello --name Felix` to generate `HELLO.md`:

```md
# 🧱 Felix

Hello Felix!

_made with 💖 by masonex_
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

Running `masonex make app_icon --url path/to/icon.png` will generate `icon.png` with the contents of `path/to/icon.png` where the `path/to/icon.png` can be either a local or remote path. Check out the [app icon example brick](https://github.com/felangel/masonex/tree/master/bricks/app_icon) to try it out.

#### Built-in Lambdas

Masonex supports a handful of built-in lambdas that can help with customizing generated code:
| Name            | Example             | Shorthand Syntax               | Full Syntax                                        |
| --------------- | ------------------- | ------------------------------ | -------------------------------------------------- |
| `camelCase`     | `helloWorld`        | `{{variable.camelCase()}}`     | `{{#camelCase}}{{variable}}{{/camelCase}}`         |
| `constantCase`  | `HELLO_WORLD`       | `{{variable.constantCase()}}`  | `{{#constantCase}}{{variable}}{{/constantCase}}`   |
| `dotCase`       | `hello.world`       | `{{variable.dotCase()}}`       | `{{#dotCase}}{{variable}}{{/dotCase}}`             |
| `headerCase`    | `Hello-World`       | `{{variable.headerCase()}}`    | `{{#headerCase}}{{variable}}{{/headerCase}}`       |
| `lowerCase`     | `hello world`       | `{{variable.lowerCase()}}`     | `{{#lowerCase}}{{variable}}{{/lowerCase}}`         |
| `mustacheCase`  | `{{ Hello World }}` | `{{variable.mustacheCase()}}`  | `{{#mustacheCase}}{{variable}}{{/mustacheCase}}`   |
| `pascalCase`    | `HelloWorld`        | `{{variable.pascalCase()}}`    | `{{#pascalCase}}{{variable}}{{/pascalCase}}`       |
| `pascalDotCase` | `Hello.World`       | `{{variable.pascalDotCase()}}` | `{{#pascalDotCase}}{{variable}}{{/pascalDotCase}}` |
| `paramCase`     | `hello-world`       | `{{variable.paramCase()}}`     | `{{#paramCase}}{{variable}}{{/paramCase}}`         |
| `pathCase`      | `hello/world`       | `{{variable.pathCase()}}`      | `{{#pathCase}}{{variable}}{{/pathCase}}`           |
| `sentenceCase`  | `Hello world`       | `{{variable.sentenceCase()}}`  | `{{#sentenceCase}}{{variable}}{{/sentenceCase}}`   |
| `snakeCase`     | `hello_world`       | `{{variable.snakeCase()}}`     | `{{#snakeCase}}{{variable}}{{/snakeCase}}`         |
| `titleCase`     | `Hello World`       | `{{variable.titleCase()}}`     | `{{#titleCase}}{{variable}}{{/titleCase}}`         |
| `upperCase`     | `HELLO WORLD`       | `{{variable.upperCase()}}`     | `{{#upperCase}}{{variable}}{{/upperCase}}`         |

_Example Usage_

Given the following example brick:

```
__brick__
  ├── {{name.snakeCase()}}.md
  └── {{name.pascalCase()}}.java
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
masonex make example --name my-name
```

The output will be:

```
├── my_name.md
└── MyName.java
```

#### Detecting Changes After Generation

Masonex supports verifying that `masonex make` did not change any files via the `--set-exit-if-changed` flag. This is often useful in continuous integration (CI) environments to ensure all generated code is up to date.

```sh
# fail with exit code 70 if any files were changed
masonex make example --name Dash --set-exit-if-changed
```

#### Custom Script Execution (Hooks)

Masonex supports custom script execution via `hooks`. The supported hooks are:

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

❗ Currently masonex only supports hooks written in [Dart](https://dart.dev).

##### Hooks Usage

Every hook must contain a `run` method which accepts a `HookContext` from `package:masonex/masonex.dart`.

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
  masonex: any
```

And `post_gen.dart` contains:

```dart
import 'package:masonex/masonex.dart';

void run(HookContext context) {
  context.logger.info('hello {{name}}!');
}
```

The result of running `masonex make example --name Dash` would be:

```sh
masonex make example --name Dash
✓ Made brick example (0.0s)
✓ Generated 1 file:
  /Users/dash/masonex/example/example.md (new)
hello Dash!
```

💡 **Note**: Scripts can contain template variables. In addition, the working directory of the script is the directory in which the code is generated.

`HookContext` can be used to access/modify the brick `vars` or to interface with the logger.

```dart
import 'package:masonex/masonex.dart';

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
masonex make example --name Dash --no-hooks
```

## Searching for Bricks

The `search` command allows developers to search published bricks on https://brickhub.dev.

### Search Usage

```sh
# search for bricks related to "bloc"
masonex search bloc
```

## Adding Bricks

The `add` command allows developers to add brick templates locally or globally on their machines from either a local path or git url. By default `masonex add` will add the template locally but bricks can be added globally by providing the `--global` (`-g`) flag.

### Add Usage

```sh
# add latest version from registry
masonex add my_brick

# add latest version from registry (global)
masonex add --global my_brick

# add version 0.1.0 from registry
masonex add my_brick 0.1.0

# add version 0.1.0 from registry (global)
masonex add --global my_brick 0.1.0

# add from registry shorthand syntax (global)
masonex add -g my_brick

# add from path
masonex add my_brick --path ./path/to/my_brick

# add from path (global)
masonex add --global my_brick --path ./path/to/my_brick

# add from path shorthand syntax (global)
masonex add -g my_brick --path ./path/to/my_brick

# add from git url
masonex add my_brick --git-url https://github.com/org/repo

# add from git url (global)
masonex add -g my_brick --git-url https://github.com/org/repo

# add from git url with path
masonex add my_brick --git-url https://github.com/org/repo --git-path path/to/my_brick

# add from git url with path and ref
masonex add my_brick --git-url https://github.com/org/repo --git-path path/to/my_brick --git-ref tag-name
```

Once a brick is added it can be used via the `masonex make` command:

```sh
masonex make <BRICK_NAME>
```

## Removing Bricks

Bricks can be removed by using the `remove` command. Use the `--global` (`-g`) flag to remove global bricks.

### Remove Usage

```sh
# remove brick
masonex remove <BRICK_NAME>

# remove brick (global)
masonex remove -g <BRICK_NAME>
```

## List Installed Bricks

All installed bricks can be seen via the `list` (`ls` for short) command.

### List Usage

```sh
# list all locally installed bricks
masonex list

# list all globally installed bricks
masonex list --global

# use alias "ls" instead of "list" for a shorthand syntax
masonex ls

# list all globally installed bricks shorthand syntax
masonex ls -g
```

## Upgrade Bricks

Installed bricks can be upgraded to their latest versions via the `upgrade` command.

### Upgrade Usage

```sh
# upgrade all local bricks and generate a new masonex-lock.json
masonex upgrade

# upgrade all global bricks
masonex upgrade --global

# upgrade all global bricks shorthand syntax
masonex upgrade -g
```

## Bundling

You can use masonex to generate a bundle for an existing template. Bundles are convenient for cases where you want to include your template as part of a standalone CLI. [Very Good CLI](https://github.com/VeryGoodOpenSource/very_good_cli) is a great example.

There are currently two types of bundles:

1. Universal - a platform-agnostic bundle
2. Dart - a Dart specific bundle

### Bundle Usage

To generate a bundle:

```sh
# Create a universal bundle from a local brick.
masonex bundle ./path/to/brick -o ./path/to/destination

# Create a dart bundle from a local brick.
masonex bundle ./path/to/brick -t dart -o ./path/to/destination

# Create a universal bundle from a git brick.
masonex bundle --source git https://github.com/:org/:repo -o ./path/to/destination

# Create a dart bundle from a git brick.
masonex bundle --source git https://github.com/:org/:repo -t dart -o ./path/to/destination

# Create a universal bundle from a hosted brick.
masonex bundle --source hosted <BRICK_NAME> -o ./path/to/destination

# Create a dart bundle from a hosted brick.
masonex bundle --source hosted <BRICK_NAME> -t dart -o ./path/to/destination
```

A bundle can then be used to generate code from a brick programmatically:

```dart
// Create a MasonexGenerator from the existing bundle.
final generator = MasonexGenerator.fromBundle(...);

// Generate code based on the bundled brick.
await generator.generate(...);
```

## Unbundling

You can use masonex to generate a brick from an existing bundle. Unbundling is useful in cases where you want to make changes to an existing bundle because you can first unbundle, make the changes to the template, and generate a new bundle.

### Unbundle Usage

To generate a brick template from an existing bundle:

```sh
# Universal Bundle
masonex unbundle ./path/to/bundle -o ./path/to/destination/

# Dart Bundle
masonex unbundle ./path/to/bundle -t dart -o ./path/to/destination/
```

## Login

You can login with a registered account via the `login` command.

### Login Usage

```sh
# login with email and password
masonex login
```

## Logout

You can logout of an account via the `logout` command.

### Logout Usage

```sh
# logout of the current account
masonex logout
```

## Publishing Bricks

You can publish a brick via the `publish` command. You must be logged in to an account with a verified email address in order to publish.

❗ **Note: once a brick has been published, it can never be unpublished.**

### Publish Usage

```sh
# publish brick in the current directory
masonex publish

# publish brick from custom path
masonex publish --directory ./path/to/brick

# publish brick from custom path shorthand syntax
masonex publish -C ./path/to/brick
```

## Complete Usage

```sh
masonex
🧱  masonex • lay the foundation!

Usage: masonex <command> [arguments]

Global options:
-h, --help       Print this usage information.
    --version    Print the current version.

Available commands:
  add        Adds a brick from a local or remote source.
  bundle     Generates a bundle from a brick template.
  cache      Interact with masonex cache.
  get        Gets all bricks in the nearest masonex.yaml.
  init       Initialize masonex in the current directory.
  list       Lists installed bricks.
  login      Log into brickhub.dev.
  logout     Log out of brickhub.dev.
  make       Generate code using an existing brick template.
  new        Creates a new brick template.
  publish    Publish the current brick to brickhub.dev.
  remove     Removes a brick.
  search     Search published bricks on brickhub.dev.
  unbundle   Generates a brick template from a bundle.
  update     Update masonex.
  upgrade    Upgrade bricks to their latest versions.

Run "masonex help <command>" for more information about a command.
```

## Video Tutorial

[![Masonex Video Tutorial](https://img.youtube.com/vi/SnrHoN632NU/0.jpg)](https://www.youtube.com/watch?v=SnrHoN632NU)

**Say HI to Masonex Package! - The Top Tier Code Generation Tool | Complete Tutorial** by [_Flutterly_](https://www.youtube.com/channel/UC5PYcSe3to4mtm3SPCUmjvw)

[masonex_demo]: https://raw.githubusercontent.com/felangel/masonex/master/assets/masonex_demo.gif
