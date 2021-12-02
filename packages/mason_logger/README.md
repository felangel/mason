# mason_logger

[![build](https://github.com/felangel/mason/workflows/mason_logger/badge.svg)](https://github.com/felangel/mason/actions)
[![coverage](https://raw.githubusercontent.com/felangel/mason/feat/mason-logger/packages/mason_logger/coverage_badge.svg)](https://github.com/felangel/mason/actions)
[![Pub](https://img.shields.io/pub/v/mason_logger.svg)](https://pub.dev/packages/mason)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A reusable logger used by the [Mason CLI](https://github.com/felangel/mason).

```dart
import 'package:mason_logger/mason_logger.dart';

Future<void> main() async {
  // Use the various APIs to log to stdout.
  final logger = Logger()
    ..info('info')
    ..alert('alert')
    ..err('error')
    ..success('success')
    ..warn('warning')
    ..detail('detail');

  // Prompt for user input.
  final favoriteAnimal = logger.prompt('What is your favorite animal?');

  // Show a progress message while performing an asynchronous operation.
  final done = logger.progress('Displaying progress');
  await Future<void>.delayed(const Duration(seconds: 1));

  // Show a completion message when the asynchronous operation has completed.
  done('Done displaying progress!');

  // Use the user provided input.
  logger.info('Your favorite animal is $favoriteAnimal!');
}
```