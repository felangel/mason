<p align="center">
<img src="https://raw.githubusercontent.com/felangel/masonex/master/assets/masonex_full.png" height="125" alt="masonex logo" />
</p>

<p align="center">
<a href="https://pub.dev/packages/masonex"><img src="https://img.shields.io/pub/v/masonex.svg" alt="Pub"></a>
<a href="https://github.com/felangel/masonex/actions"><img src="https://github.com/felangel/masonex/workflows/masonex/badge.svg" alt="masonex"></a>
<a href="https://github.com/felangel/masonex/actions"><img src="https://raw.githubusercontent.com/felangel/masonex/master/packages/masonex/coverage_badge.svg" alt="coverage"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

---

A template generator which helps teams generate files quickly and consistently.

`package:masonex` contains the core generator that powers [package:masonex_cli](https://pub.dev/packages/masonex_cli) and can be used to build custom code generation tools.

> [!NOTE]
> This is a fork originally developed by **Jules** and **Antigravity**.

## File Generation Process

`masonex` extends the standard `mason` logic to provide a more robust and flexible template generation process, including support for binary data and advanced template syntax.

### How it works

1. **Brick Loading**: The generator loads the `brick.yaml` and maps all files within the `__brick__` directory as `TemplateFile` objects, preserving their original byte content.
2. **Substitution Phase**:
   - **Path Substitution**: File paths are rendered using Mustache, supporting dynamic names and loops for multiple file generation.
   - **Binary Data Protection**: Before rendering, `masonex` detects binary variables (`List<int>` or `Uint8List`) and replaces them with text markers. This prevents the binary data from being corrupted during the UTF-8 rendering process.
   - **Syntax Transpilation**: Supports extended syntax like pipes (`{{ var | pascalCase }}`), dot notation (`{{ var.camelCase() }}`), and alternative closing tags (`{{%name}}`).
   - **Mustache Rendering**: The content is rendered using the [mustachex](https://gitlab.com/Rodsevich/mustachex) engine, enabling advanced Lambdas and Partials.
   - **Binary Restoration**: After rendering, the original raw bytes are re-injected into the positions of the markers.
3. **Output Generation**: The `GeneratorTarget` writes the final files to disk, handling conflict resolutions (overwrite, skip, or append).

## Advanced File Processing (Prefixes)

`masonex` introduces special filename prefixes within the `__brick__` directory to provide fine-grained control over how files are generated or merged:

| Prefix | Action | Description |
| :--- | :--- | :--- |
| `>>>` | **Merge** | Recursively merges iterable variables (Lists, Sets, Maps) in Dart, JSON, and YAML files. |
| `>` | **Overwrite** | Always overwrites the target file, regardless of conflict resolution settings. |
| `>>` | **Append** | Always appends the content to the end of the existing file. |
| `<<` | **Prepend** | Always inserts the content at the beginning of the existing file. |
| `!` | **Safe Check** | Only generates the file if it does *not* exist. Skips otherwise. |
| `~` | **Temporary** | Generates the file but deletes it immediately after the generation process finishes. |
| `?var?` | **Conditional** | Generates the file only if `var` evaluates to `true` or is a non-empty list. |
| `*var*` | **Iterator** | Generates multiple files by iterating over the `var` list. Use `{{item}}` in the filename. |
| `%id%` | **Snippet** | Marks the file as a fragment for in-file generation points defined by `@GenerateBefore(id)`, etc. |

### Dart Merging Logic

When using the `>>>` prefix for `.dart` files:
- **Lists**: New elements are appended.
- **Sets**: Merged with existing elements, preserving uniqueness.
- **Maps**: New keys are added, and existing keys are overwritten with new values.
- **Imports**: Missing imports are automatically added to the top of the file.
- **Top-level Declarations**: New classes, functions, or variables that don't exist in the target are appended.
- **Scoped Merging**: Correctly identifies and merges fields inside classes based on qualified names.

## In-File Generations

Use `package:masonex_annotations` to mark points in your source code where templates should be injected.

### Annotations
- `@GenerateBefore('id')`
- `@GenerateAfter('id')`
- `@GenerationMerge('id')`

### Workflow
1. Annotate your Dart code:
   ```dart
   @GenerateAfter('plugins'): // {{new_plugin_config}}
   final plugins = [];
   ```
2. Run `mustachex build` to scan the repo and update your `brick.yaml`.
3. When the brick is generated, `masonex` will inject snippets marked with `%id%` into the corresponding annotated points.

## Usage

```dart
import 'dart:io';

import 'package:masonex/masonex.dart';

Future<void> main() async {
  final brick = Brick.git(
    const GitPath(
      'https://github.com/felangel/masonex',
      path: 'bricks/greeting',
    ),
  );
  final generator = await MasonexGenerator.fromBrick(brick);
  final target = DirectoryGeneratorTarget(Directory.current);
  await generator.generate(target, vars: <String, dynamic>{'name': 'Dash'});
}
```
