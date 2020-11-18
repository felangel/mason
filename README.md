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

`greetings.md`

```md
# Greetings {{name}}!
```

## Build

```sh
mason build -t greetings.yaml -- --name Felix
```

The above command should generate `GREETINGS.md` file with the following content:

```md
# Greetings Felix!
```

## Usage

```sh
$ mason --help
⛏️  mason • lay the foundation!
Usage: mason <command> [<args>]
Commands:
  build   build new component from a template
Arguments:
  -t, --template    template yaml path
  -h, --help        Prints usage information.
      --version     Print the current version.
```
