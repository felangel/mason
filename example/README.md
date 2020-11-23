# Usage

## Basic

Run the following command in the current directory:

```sh
mason build greetings -- --name Felix
```

`GREETINGS.md` should be created in the current directory with the following contents:

```md
# Greetings Felix!
```

## Loops and JSON

Run the following command in the current directory:

```sh
mason build todos --json todos.json
```

`TODOS.md` should be created in the current directory with the following contents:

```md
# TODOS

-  [X]  Eat
-  [X]  Code
-  [ ]  Sleep
```
