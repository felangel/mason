# Usage

## Basic

Run the following command in the current directory:

```sh
mason get # only first time
mason make greeting --name Felix
```

`GREETINGS.md` should be created in the current directory with the following contents:

```md
# Greetings Felix!
```

## Loops and JSON

Run the following command in the current directory:

```sh
mason get # only first time
mason make todos -c todos.json
```

`TODOS.md` should be created in the current directory with the following contents:

```md
# TODOS

-  [X]  Eat
-  [X]  Code
-  [ ]  Sleep
```
