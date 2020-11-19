# Usage

Run the following command in the current directory:

```sh
mason build -t templates/greetings/greetings.yaml -- --name Joe
```

`GREETINGS.md` should be created in the current directory with the following contents:

```md
# Greetings Joe!
```

## Usage with variable file

Rull the following command in the current directory:

```sh
mason build -t templates/from_variable_file/from_variable_file.yaml --vars-file templates/from_variable_file/variables.yaml
```

`generated.md` should be created in the current directory with the following contents:

```md
# Good Afternoon Marcus! This is populated by a yaml file.
```
