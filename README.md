<p align="center">
<img src="https://raw.githubusercontent.com/felangel/mason/master/assets/mason_logo.png" height="200" alt="mason logo" />
</p>

<p align="center">
<a href="https://pub.dev/packages/mason"><img src="https://img.shields.io/pub/v/mason.svg" alt="Pub"></a>
<a href="https://github.com/felangel/mason/actions"><img src="https://github.com/felangel/mason/workflows/mason/badge.svg" alt="mason"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

---

Mason allows developers to create and consume reusable templates called bricks.

## Quick Start

### Installing

```sh
# Activate from pub.dev
$ pub global activate mason

# Or install using Homebrew
$ brew tap felangel/mason
$ brew install mason
```

### Initializing

```sh
$ mason init
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
$ mason get
```

Then you can use `mason make` to generate your first file:

```sh
$ mason make hello
```

### Command Line Variables

Any variables can be passed as command line args.

```sh
$ mason make hello --name Felix
```

### Variable Prompts

Any variables which aren't specified as command line args will be prompted.

```sh
$ mason make hello
name: Felix
```

### JSON Input Variables

Any variables can be passed via json file:

```dart
$ mason make hello --json hello.json
```

where `hello.json` is:

```json
{
  "name": "Felix"
}
```

The above commands will all generate `HELLO.md` in the current directory with the following content:

```md
Hello Felix!
```

## Creating New Bricks

Create a new brick using the `mason new` command.

```sh
$ mason new <BRICK_NAME>
```

The above command will generate a new brick in the `bricks` directory with a `brick.yaml` and `__brick__` template directory.

### Brick YAML

The `brick.yaml` contains metadata for a `brick` template.

```yaml
name: example
description: An example brick
vars:
  - name
```

### Brick Template

Write your brick template in the `__brick__` directory using [mustache templates](https://mustache.github.io/). See the [mustache manual](https://mustache.github.com/mustache.5.html) for detailed usage information.

`__brick__/example.md`

```md
# Hello {{name}}!
```

❗ **Note: `__brick__` can contain multiple files and subdirectories**

#### File Resolution

It is possible to resolve files based on path input variables using the `<% %>` tag.

For example, given the following `brick.yaml`:

```yaml
name: app_icon
description: Create an app_icon file from a URL
vars:
  - url
```

And the following brick template:

`__brick__/<% url %>`

Running `mason make app_icon -- --url path/to/icon.png` will generate `icon.png` with the contents of `path/to/icon.png` where the `path/to/icon.png` can be either a local or remote path.

## Usage

```sh
$ mason --help
⛏️  mason • lay the foundation!

Usage: mason <command> [arguments]

Global options:
-h, --help       Print this usage information.
    --version    Print the current version.

Available commands:
  cache   Interact with mason cache
  get     Gets all bricks.
  init    Initialize mason in the current directory.
  make    Generate code using an existing brick template.
  new     Creates a new brick template.
```
