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
