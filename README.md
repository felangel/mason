# ⛏️ mason

[![pub](https://img.shields.io/pub/v/mason.svg)](https://pub.dev/packages/mason)
[![mason](https://github.com/felangel/mason/workflows/mason/badge.svg?branch=master)](https://github.com/felangel/mason/actions)

A template generator which helps teams generate files quickly and consistently.

Mason allows developers to create and consume resuable templates call bricks.

## Activating Mason

`pub global activate mason`

## Creating Custom Brick Templates

### Create a Brick YAML

The `brick.yaml` contains metadata for a `brick` template.

`brick.yaml`

```yaml
name: greetings
description: A Simple Greetings Brick
vars:
  - name
```

### Create a Brick Template

Write your brick template in `__brick__` using [mustache templates](https://mustache.github.io/). See the [mustache manual](https://mustache.github.com/mustache.5.html) for detailed usage information.

`__brick__/greetings.md`

```md
# Greetings {{name}}!
```

❗ **Note: bricks can consist of multiple files and subdirectories**

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

## Consuming Brick Templates

### Create a Mason YAML

```sh
$ mason init
```

Add bricks to the newly generated `mason.yaml`:

```yaml
bricks:
  greetings:
    path: bricks/greetings
  todos:
    git:
      url: git@github.com:felangel/mason.git
      path: bricks/todos
```

Then you can use `mason make <greetings|todos>`:

```sh
mason make greetings
mason make todos
```

### Command Line Variables

Any variables can be passed as command line args.

```sh
$ mason make greetings -- --name Felix
```

### Variable Prompts

Any variables which aren't specified as command line args will be prompted.

```sh
$ mason make greetings
name: Felix
```

### JSON Input Variables

Any variables can be passed via json file:

```dart
$ mason make greetings --json greetings.json
```

where `greetings.json` is:

```json
{
  "name": "Felix"
}
```

The above commands should all generate `GREETINGS.md` in the current directory with the following content:

```md
# Greetings Felix!
```

## Usage

```sh
$ mason --help
⛏️  mason • lay the foundation!

Usage: mason <command> [arguments]

Global options:
-h, --help       Print this usage information.
    --version    Print the current version.

Available commands:
  init   Initialize a new mason.yaml.
  make   Generate code using an existing brick template.
```
