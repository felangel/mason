# ⛏️ mason

[![pub](https://img.shields.io/pub/v/mason.svg)](https://pub.dev/packages/mason)
[![mason](https://github.com/felangel/mason/workflows/mason/badge.svg?branch=master)](https://github.com/felangel/mason/actions)

A Dart template generator which helps teams generate files quickly and consistently.

## Activate Mason

`pub global activate mason`

## Define Template YAML

`greetings.yaml`

```yaml
name: greetings
description: A Simple Greetings Template
files:
  - from: greetings.md # template file (input)
    to: GREETINGS.md # generated file (output)
vars:
  - name
```

## Define Template File(s)

Write your template using [mustache templates](https://mustache.github.io/). See the [mustache manual](http://mustache.github.com/mustache.5.html) for detailed usage information.

`greetings.md`

```md
# Greetings {{name}}!
```

## Build

### Command Line Variables

Any variables can be passed as command line args.

```sh
$ mason build -t greetings.yaml -- --name Felix
```

### Variable Prompts

Any variables which aren't specified as command line args will be prompted.

```sh
$ mason build -t greetings.yaml
name: Felix
```

The above command should generate `GREETINGS.md` file with the following content:

```md
# Greetings Felix!
```

## Using Mason YAML

Optionally define a `mason.yaml` at the root directory of your project.

```yaml
templates:
  greetings:
    path: ./greetings.yaml
  widget:
    path: https://raw.githubusercontent.com/felangel/mason/master/example/templates/widget/widget.yaml
```

Then you can use `mason build <greetings|widget>`:

```sh
mason build greetings -- --name Felix
mason build widget -- --name my_widget
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
