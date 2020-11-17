# mason

![pub](https://img.shields.io/pub/v/mason.svg)
![mason](https://github.com/felangel/mason/workflows/mason/badge.svg?branch=master)

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
mason build --template greetings.yaml -- --name Felix
```

The above command should generate `GREETINGS.md` file with the following content:

```md
# Greetings Felix!
```
