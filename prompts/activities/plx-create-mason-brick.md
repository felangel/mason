Please create all necessary files and directories for a new Mason brick based on `{user_requests}` and `{relevant_context}`, gather any missing details through clarification, and ensure that the brick is fully implemented in the `{brick_output_directory}`.

### Core Knowledge & Definitions You Must Adhere To

**1. What is a Mason Brick?**
A Mason brick is a reusable template used for code generation. It consists of:
    *   A `brick.yaml` manifest file.
    *   A `__brick__` directory containing the template files and subdirectories.

**2. `brick.yaml` - The Manifest File**
This YAML file defines the brick's metadata and variables. Key fields include:
    *   `name`: (string) The brick's name. This should be `snake_case`.
    *   `description`: (string) A brief description of what the brick does.
    *   `version`: (string) Semantic versioning for the brick (e.g., `0.1.0+1`).
    *   `environment`: (map) Specifies Mason CLI compatibility.
        *   `mason`: (string) The Mason CLI version constraint (e.g., `{default_mason_env_version}`).
    *   `repository`: (string, optional) URL of the brick's source code repository.
    *   `publish_to`: (string, optional) Registry URL for publishing, or `none` for private bricks.
    *   `vars`: (map, optional) Defines dynamic input variables for the brick. Each variable is a map with properties:
        *   `type`: (string) The type of the variable. Can be `string`, `number`, `boolean`, `enum`, `array`, or `list`.
        *   `description`: (string, optional) A short explanation of the variable.
        *   `default`: (any, optional) A default value if the user doesn't provide one. For `boolean`, this is `true` or `false`.
        *   `defaultValues`: (list, optional) For `array` type, a list of default selected values from the `values` list.
        *   `prompt`: (string, optional) A custom message displayed to the user when asking for this variable's value. If omitted, the variable's name is used.
        *   `values`: (list, optional) For `enum` and `array` types, a list of predefined choices for the user.
        *   `separator`: (string, optional) For `list` type, the separator used to split the user's input string into a list. Defaults to `,`.

**3. `__brick__` Directory - The Template**
This directory contains all the files and subdirectories that will be generated.
    *   **Templating Engine:** Uses **Mustache** for dynamic content.
        *   `{{ variable }}`: For inserting the value of `variable` (HTML-escaped).
        *   `{{{ variable }}}`: For inserting the value of `variable` without HTML-escaping.
        *   `{{#section}}...{{/section}}`: Conditional blocks. Renders if `section` is true, not false, or not an empty list. If `section` is a list, it iterates over the items.
        *   `{{^section}}...{{/section}}`: Inverted conditional blocks. Renders if `section` is false, null, or an empty list.
        *   `{{> partialName }}`: Includes a partial template. `partialName` refers to a file like `{{ ~my_partial.md }}` located at the root of the `__brick__` directory.
    *   **Dynamic File/Directory Names:** Use Mustache syntax in filenames or directory names. Example: `{{name.snakeCase()}}.dart`.
    *   **File Content Resolution:** A filename like `{{% path_variable %}}` will result in a file whose name is the value of `path_variable`, and its content will be the content of the file specified by `path_variable` (can be a local or remote URL).

**4. Partials**
    *   Partials are reusable template snippets.
    *   Their filenames must start with `{{ ~` (e.g., `{{ ~common_header.md }}`).
    *   Partials **must** be located directly within the `__brick__` directory (not in subdirectories).
    *   They are included in other templates using `{{> partialName }}` (e.g., `{{> common_header.md }}`).

**5. Built-in Lambdas (Case Conversions)**
Mason provides built-in lambdas for case conversion, accessible via `.` notation:
    *   `camelCase`, `constantCase`, `dotCase`, `headerCase`, `lowerCase`, `mustacheCase`, `pascalCase`, `pascalDotCase`, `paramCase`, `pathCase`, `sentenceCase`, `snakeCase`, `titleCase`, `upperCase`.
    *   Usage: `{{variable.lambdaName()}}` or `{{#lambdaName}}{{variable}}{{/lambdaName}}`.

**6. Hooks (Optional Custom Dart Scripts)**
    *   `pre_gen.dart`: Executed *before* files are generated.
    *   `post_gen.dart`: Executed *after* files are generated.
    *   Location: Place these scripts in a `hooks` directory at the root of the brick (alongside `brick.yaml` and `__brick__`).
    *   `hooks/pubspec.yaml`: Each hook script needs a `pubspec.yaml` in the `hooks` directory.
        *   Example:
            ```yaml
            name: {{brick_name}}_hooks
            environment:
              sdk: {default_hook_sdk_version}
            dependencies:
              mason: {default_mason_hook_dependency_version}
            ```
    *   `hooks/.gitignore`: Typically includes:
        ```
        .dart_tool
        .packages
        pubspec.lock
        build
        ```
    *   Script Structure: Each Dart hook script must contain a `run` method: `void run(HookContext context) { ... }`.
        *   `HookContext` provides access to `vars` (read/write) and a `logger`.

**7. Standard Files (Best Practices)**
Include these files in your brick's root directory:
    *   `README.md`: Instructions, description, and usage for the brick.
    *   `CHANGELOG.md`: History of changes and versions.
    *   `LICENSE`: Specifies the license under which the brick can be used (e.g., MIT).

### Operational Instructions

**1. Interaction & Clarification:**
    *   Carefully analyze the `{user_requests}`.
    *   If the request is ambiguous, or if details for `brick.yaml` (especially `vars`), template file content, or hook logic are missing, **you MUST ask targeted clarifying questions**. Your goal is to gather all necessary information to design a "perfect brick" that meets the user's needs. Do not proceed with file creation until you have 100% certainty.

**2. Brick Naming:**
    *   The primary name for the brick (used for the root directory and the `name` field in `brick.yaml`) should be derived from the `{user_requests}` and converted to `snake_case`. For example, if the user asks for "My Awesome Feature", the brick name becomes `my_awesome_feature`. This derived name will be referred to as `{brick_name_snake_case}`.

**3. Default Generation (If user does not specify all details):**
If the `{user_requests}` does not specify all details for the brick's content, use these sensible defaults to *create* the files:
    *   **`brick.yaml`:**
        *   `name`: (`{brick_name_snake_case}`).
        *   `description`: "A new brick created with Mason." (Or a more specific one if inferable from `{user_requests}`).
        *   `version`: `0.1.0+1`.
        *   `environment`: `{ mason: {default_mason_env_version} }`.
        *   `vars`: If no variables are specified by the user, include a default `name` variable:
            ```yaml
            vars:
              name:
                type: string
                description: Your name
                default: Dash
                prompt: What is your name?
            ```
    *   **`__brick__` Directory:**
        *   Create a simple template file, e.g., `__brick__/HELLO.md` (or `__brick__/{{{brick_name_snake_case}}}/{{name.snakeCase()}}.md` if a `name` var exists in `vars` and the brick structure is more complex) with content like: `Hello {{name}}!`.
    *   **Standard Files:**
        *   `README.md` (fill `{brick_name_snake_case}` and `{{description from brick.yaml}}`):
            ```markdown
            # {brick_name_snake_case}

            [![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)

            {{description from brick.yaml}}

            _Generated by [mason][1] 🧱_

            ## Getting Started 🚀

            This is a starting point for a new brick.
            A few resources to get you started if this is your first brick template:

            - [Official Mason Documentation][2]
            - [Code generation with Mason Blog][3]
            - [Very Good Livestream: Felix Angelov Demos Mason][4]
            - [Flutter Package of the Week: Mason][5]
            - [Observable Flutter: Building a Mason brick][6]
            - [Meet Mason: Flutter Vikings 2022][7]

            [1]: https://github.com/felangel/mason
            [2]: https://docs.brickhub.dev
            [3]: https://verygood.ventures/blog/code-generation-with-mason
            [4]: https://youtu.be/G4PTjA6tpTU
            [5]: https://youtu.be/qjA0JFiPMnQ
            [6]: https://youtu.be/o8B1EfcUisw
            [7]: https://youtu.be/LXhgiF5HiQg
            ```
        *   `CHANGELOG.md`:
            ```markdown
            # 0.1.0+1

            - TODO: Describe initial release.
            ```
        *   `LICENSE`:
            ```
            TODO: Add your license here.
            ```
    *   **Hooks (If requested without specific logic):**
        *   `hooks/pre_gen.dart`:
            ```dart
            import 'package:mason/mason.dart';

            void run(HookContext context) {
              // TODO: add pre-generation logic.
            }
            ```
        *   `hooks/post_gen.dart`:
            ```dart
            import 'package:mason/mason.dart';

            void run(HookContext context) {
              // TODO: add post-generation logic.
            }
            ```
        *   `hooks/pubspec.yaml` (fill `{brick_name_snake_case}`):
            ```yaml
            name: {brick_name_snake_case}_hooks
            environment:
              sdk: {default_hook_sdk_version}
            dependencies:
              mason: {default_mason_hook_dependency_version}
            ```
        *   `hooks/.gitignore`:
            ```
            .dart_tool
            .packages
            pubspec.lock
            build
            ```

**4. Brick Creation & File Generation Process:**
Once all necessary information is gathered and confirmed:
    1.  **Finalize Design:** Determine the complete and final brick structure, including all files, directories, their exact paths relative to the brick's root, and their full content based on user specifications, clarifications, and defaults.
    2.  **Establish Root Directory:** The root directory for the new brick will be `{brick_output_directory}/{brick_name_snake_case}/`.
    3.  **Create Root Directory:** Create the directory `{brick_output_directory}/{brick_name_snake_case}/`.
    4.  **Create `brick.yaml`:** Create the `brick.yaml` file within the root directory (`{brick_output_directory}/{brick_name_snake_case}/brick.yaml`) with its fully finalized YAML content.
    5.  **Create `__brick__` Directory:** Create the `__brick__` directory within the root (`{brick_output_directory}/{brick_name_snake_case}/__brick__/`).
    6.  **Populate `__brick__`:**
        *   For each template file and partial defined in the finalized design:
            *   Create any necessary subdirectories within `__brick__`.
            *   Create the file (e.g., `{brick_output_directory}/{brick_name_snake_case}/__brick__/path/to/template_file.md`) and write its complete Mustache template content.
    7.  **Create Hooks (If Applicable):**
        *   If hooks are part of the finalized design:
            *   Create the `hooks` directory within the root (`{brick_output_directory}/{brick_name_snake_case}/hooks/`).
            *   Create `pre_gen.dart`, `post_gen.dart`, `pubspec.yaml`, and `.gitignore` within the `hooks` directory, each with their finalized content.
    8.  **Create Standard Files:**
        *   Create `README.md`, `CHANGELOG.md`, and `LICENSE` within the root directory (`{brick_output_directory}/{brick_name_snake_case}/`), each with their finalized content (using defaults if not specified).
    9.  **File System Operations:** You are to perform these directory and file creation/writing operations directly.
    10. **Report Success:** After all files and directories have been successfully created, report back to the user with a success message, including the name of the brick and the full path where it was created (e.g., "Successfully created the '{brick_name_snake_case}' brick at '{brick_output_directory}/{brick_name_snake_case}/'.").

### Constraints & Best Practices

*   **Adherence to Conventions:** Strictly follow Mason file structure (`brick.yaml`, `__brick__/`, `hooks/`), naming conventions (snake_case for brick name), and templating syntax.
*   **Valid Templates:** Ensure any Mustache templates you design and create are syntactically valid.
*   **Complete and Correct Files:** Ensure all generated files and their contents are complete as per the finalized specification, syntactically correct, and accurately placed within the brick's directory structure.
*   **Versioning:**
    *   Use `{default_mason_env_version}` for `environment.mason` in `brick.yaml` if not otherwise specified.
    *   Use `{default_mason_hook_dependency_version}` for the `mason` dependency in `hooks/pubspec.yaml` if hooks are included and not otherwise specified.
    *   Use `{default_hook_sdk_version}` for the `sdk` constraint in `hooks/pubspec.yaml` if hooks are included and not otherwise specified.

```yaml
default_mason_env_version: "^0.1.2"
default_mason_hook_dependency_version: "^0.1.2"
default_hook_sdk_version: "^3.5.4"
brick_output_directory: .
relevant_context: <file_map>, <file_contents>, <extra_context>
user_requests: Please create a mason brick
```

```xml
<extra_context>
</extra_context>
```