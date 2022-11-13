# 0.2.3

- fix: windows progress animation

# 0.2.2

- fix: only animate progress on terminals

# 0.2.1

- fix: improve clear line mechanism for Progress API

# 0.2.0

- **BREAKING** feat: add generic support to `chooseOne` and `chooseAny`

  ```dart
  enum Shape { square, circle, triangle}

  void main() {
    final logger = Logger();

    final shape = logger.chooseOne<Shape>(
      'What is your favorite shape?',
      choices: Shape.values,
      display: (shape) => '${shape.name}',
    );
    logger.info('You chose: $shape');

    final shapes = logger.chooseAny<Shape>(
      'Or did you want to choose multiples?',
      choices: Shape.values,
      defaultValues: [shape],
      display: (shape) => '${shape.name}',
    );
    logger.info('You chose: $shapes');
  }
  ```

# 0.1.4

- feat: add `ProgressOptions` API

  ```dart
  import 'package:mason_logger/mason_logger.dart';

  Future<void> main() async {
    // 1. ✨ Create a custom ProgressOptions.
    const progressOptions = ProgressOptions(
      animation: ProgressAnimation(
        frames: ['🌑', '🌒', '🌓', '🌔', '🌕', '🌖', '🌗', '🌘'],
      ),
    );

    // 2. 💉 Inject `progressOptions` into your Logger.
    final logger = Logger(progressOptions: progressOptions);

    // 3. 🤤 Admire your custom progress animation.
    final progress = logger.progress('Calculating');
    await Future.delayed(const Duration(seconds: 3));
    progress.complete('Done!');
  }
  ```

# 0.1.3

- feat: add `link` API

  ```dart
  final logger = Logger();
  final repoLink = link(
    message: 'GitHub Repository',
    uri: Uri.parse('https://github.com/felangel/mason'),
  );
  logger.info('To learn more, visit the $repoLink.');
  ```

# 0.1.2

- feat: render milliseconds on progress duration
- refactor(deps): remove `package:meta`
- refactor: use `IOOverrides`

# 0.1.1

- refactor(deps): remove `pkg:universal_io`
- docs: fix typo in `README` snippet

# 0.1.0

- **BREAKING**: support log levels (default `Level` is `Level.info`)
- **BREAKING**: mark `Progress()` as `@internal`
- **BREAKING**: `alert` writes to `stderr` instead of `stdout`
- **BREAKING**: `Progress.fail(...)` writes to `stdout` instead of `stderr`
- **BREAKING**: remove deprecated `Progress.call(...)` (use `Progress.complete` instead).

# 0.1.0-dev.14

- feat: `Progress.update`
  ```dart
  final progress = logger.progress('Calculating');
  await Future<void>.delayed(const Duration(milliseconds: 500));
  progress.update('Halfway!');
  await Future<void>.delayed(const Duration(milliseconds: 500));
  progress.complete('Done!');
  ```

# 0.1.0-dev.13

- fix: correct J and K key mappings

# 0.1.0-dev.12

- fix: `chooseOne` API windows compatibility
- feat: `chooseAny`
  ```dart
  /// Ask user to choose zero or more options.
  final desserts = logger.chooseAny(
    'Which desserts do you like?',
    choices: ['🍦', '🍪', '🍩'],
  );
  ```

# 0.1.0-dev.11

- fix: write errors and warnings to `stderr`
  - `Logger().err(...)`
  - `Logger().warn(...)`
  - `Logger().progress(...).fail(...)`

# 0.1.0-dev.10

- feat: `chooseOne` API

  ```dart
  final favoriteColor = logger.chooseOne(
    'What is your favorite color?',
    choices: ['red', 'green', 'blue'],
    defaultValue: 'blue',
  );
  ```

# 0.1.0-dev.9

- feat: `progress` API enhancements
  ```dart
  final progress = Logger().progress('calculating');
  try {
    await _performCalculation();
    // Complete progress successfully.
    progress.complete();
  } catch (error, stackTrace) {
    // Terminate progress unsuccessfully.
    progress.fail();
  }
  ```

# 0.1.0-dev.8

- fix: single line prompts are overwritten
  - when using `confirm` and `prompt`

# 0.1.0-dev.7

- fix: multiline prompts are outputting twice
  - when using `confirm` and `prompt`

# 0.1.0-dev.6

- feat: add `write`

# 0.1.0-dev.5

- feat: add `hidden` flag to `prompt`
- chore: upgrade to Dart 2.16

# 0.1.0-dev.4

- fix: `progress` string truncation
- feat: add `confirm`
- feat: add `defaultValue` to `prompt`
- feat: improve `progress` time style
- docs: update example and `README`

# 0.1.0-dev.3

- feat: add `tag` to `warn` call

# 0.1.0-dev.2

- test: 100% test coverage
- docs: README updates to include usage
- docs: include example

# 0.1.0-dev.1

**Dev Release**

- chore: initial package (🚧 under construction 🚧)
