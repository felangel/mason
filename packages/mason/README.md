<p align="center">
<img src="https://raw.githubusercontent.com/felangel/mason/master/assets/mason_full.png" height="125" alt="mason logo" />
</p>

<p align="center">
<a href="https://pub.dev/packages/mason"><img src="https://img.shields.io/pub/v/mason.svg" alt="Pub"></a>
<a href="https://github.com/felangel/mason/actions"><img src="https://github.com/felangel/mason/workflows/mason/badge.svg" alt="mason"></a>
<a href="https://github.com/felangel/mason/actions"><img src="https://raw.githubusercontent.com/felangel/mason/refactor/mason_cli/packages/mason/coverage_badge.svg" alt="coverage"></a>
<a href="https://pub.dev/packages/very_good_analysis"><img src="https://img.shields.io/badge/style-very_good_analysis-B22C89.svg" alt="style: very good analysis"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

---

Mason contains the core generator that powers [mason_cli](https://pub.dev/packages/mason_cli).

`package:mason` allows developers to build custom CLIs and other tooling that leverages the mason generator.

```dart
import 'dart:io';

import 'package:mason/mason.dart';

Future<void> main() async {
  final generator = await MasonGenerator.fromGitPath(
    const GitPath(
      'https://github.com/felangel/mason.git',
      path: 'bricks/greeting',
    ),
  );
  final target = DirectoryGeneratorTarget(Directory.current);
  await generator.generate(target, vars: <String, dynamic>{'name': 'Dash'});
}
```
