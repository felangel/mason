# ⛏️ mason

[![pub](https://img.shields.io/pub/v/mason.svg)](https://pub.dev/packages/mason)
[![mason](https://github.com/felangel/mason/workflows/mason/badge.svg?branch=master)](https://github.com/felangel/mason/actions)

A Dart template generator which helps teams generate files quickly and consistently.

`pub global activate mason`

## Creating Custom Templates

### Define Template YAML

`greetings.yaml`

```yaml
name: greetings
description: A Simple Greetings Template
vars:
  - name
```

### Define Template

Write your template in `__template__` using [mustache templates](https://mustache.github.io/). See the [mustache manual](https://mustache.github.com/mustache.5.html) for detailed usage information.

`__template__/greetings.md`

```md
# Greetings {{name}}!
```

## Consuming Templates

### Create a Mason YAML

Define a `mason.yaml` at the root directory of your project.

```yaml
templates:
  greetings:
    path: ./greetings.yaml
  widget:
    git:
      url: git@github.com:felangel/mason.git
      path: templates/widget/template.yaml
```

Then you can use `mason build <greetings|widget>`:

```sh
mason build greetings -- --name Felix
mason build widget -- --name my_widget
```

### Command Line Variables

Any variables can be passed as command line args.

```sh
$ mason build greetings -- --name Felix
```

### Variable Prompts

Any variables which aren't specified as command line args will be prompted.

```sh
$ mason build greetings
name: Felix
```

The above command should generate `GREETINGS.md` in the current directory with the following content:

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
  build   Generate code using an existing template.
```
