import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:path/path.dart' as p;

/// {@template new_command}
/// `mason new` command which creates a new brick.
/// {@endtemplate}
class NewCommand extends MasonCommand {
  /// {@macro new_command}
  NewCommand({super.logger}) {
    argParser
      ..addFlag(
        'hooks',
        help: 'Generate hooks as part of the new brick.',
        negatable: false,
      )
      ..addOption(
        'desc',
        abbr: 'd',
        help: 'Description of the new brick template',
        defaultsTo: 'A new brick created with the Mason CLI.',
      )
      ..addOption(
        'output-dir',
        abbr: 'o',
        help: 'Directory where to output the new brick.',
        defaultsTo: '.',
      );
  }

  @override
  final String description = 'Creates a new brick template.';

  @override
  final String name = 'new';

  @override
  Future<int> run() async {
    if (results.rest.isEmpty) {
      usageException('Name of the new brick is required.');
    }
    final name = results.rest.first.snakeCase;
    final description = results['desc'] as String;
    final outputDir = canonicalize(
      p.join(cwd.path, results['output-dir'] as String),
    );
    final createHooks = results['hooks'] == true;
    final directory = Directory(outputDir);
    final target = DirectoryGeneratorTarget(directory);
    const vars = <String, dynamic>{'name': '{{name}}'};
    final generator = _BrickGenerator(
      name,
      description,
      createHooks: createHooks,
    );
    final progress = logger.progress('Creating new brick: $name.');

    try {
      await generator.generate(target, vars: vars, logger: logger);
      progress.complete('Generated ${generator.files.length} file(s).');
      logger.flush((message) => logger.info(darkGray.wrap(message)));
      return ExitCode.success.code;
    } catch (_) {
      progress.fail();
      rethrow;
    }
  }
}

class _BrickGenerator extends MasonGenerator {
  _BrickGenerator(
    this.brickName,
    this.brickDescription, {
    this.createHooks = false,
  }) : super(
          '__new_brick__',
          'Creates a new brick.',
          files: [
            TemplateFile(
              p.join(brickName, BrickYaml.file),
              _brickYamlContent(brickName, brickDescription),
            ),
            TemplateFile(
              p.join(brickName, 'README.md'),
              _brickReadmeContent(brickName, brickDescription),
            ),
            TemplateFile(
              p.join(brickName, 'CHANGELOG.md'),
              _brickChangelogContent,
            ),
            TemplateFile(
              p.join(brickName, 'LICENSE'),
              _brickLicenseContent,
            ),
            TemplateFile(
              p.join(brickName, BrickYaml.dir, 'HELLO.md'),
              'Hello {{name}}!',
            ),
            if (createHooks) ...[
              TemplateFile(
                p.join(brickName, BrickYaml.hooks, 'pubspec.yaml'),
                _hooksPubspecContent(brickName),
              ),
              TemplateFile(
                p.join(brickName, BrickYaml.hooks, 'pre_gen.dart'),
                _hooksPreGenContent,
              ),
              TemplateFile(
                p.join(brickName, BrickYaml.hooks, 'post_gen.dart'),
                _hooksPostGenContent,
              ),
              TemplateFile(
                p.join(brickName, BrickYaml.hooks, '.gitignore'),
                _hooksGitignoreContent,
              ),
            ],
          ],
        );

  static String _brickYamlContent(String name, String description) => '''
name: $name
description: $description

# The following defines the brick repository url.
# Uncomment and update the following line before publishing the brick.
# repository: https://github.com/my_org/my_repo

# The following defines the version and build number for your brick.
# A version number is three numbers separated by dots, like 1.2.34
# followed by an optional build number (separated by a +).
version: 0.1.0+1

# The following defines the environment for the current brick.
# It includes the version of mason that the brick requires.
environment:
  mason: ^$packageVersion

# Variables specify dynamic values that your brick depends on.
# Zero or more variables can be specified for a given brick.
# Each variable has:
#  * a type (string, number, boolean, enum, array, or list)
#  * an optional short description
#  * an optional default value
#  * an optional list of default values (array only)
#  * an optional prompt phrase used when asking for the variable
#  * a list of values (enums only)
#  * an optional separator (list only)
vars:
  name:
    type: string
    description: Your name
    default: Dash
    prompt: What is your name?
''';

  static String _brickReadmeContent(String name, String description) => '''
# $name

[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)

$description

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
''';

  static const _brickChangelogContent = '''
# 0.1.0+1

- TODO: Describe initial release.
''';

  static const _brickLicenseContent = '''
TODO: Add your license here.
''';

  static String _hooksPubspecContent(String name) => '''
name: ${name}_hooks

environment:
  sdk: ^3.5.4

dependencies:
  mason: ^$packageVersion
''';

  static const _hooksGitignoreContent = '''
.dart_tool
.packages
pubspec.lock
build
''';

  static const _hooksPreGenContent = '''
import 'package:mason/mason.dart';

void run(HookContext context) {
  // TODO: add pre-generation logic.
}
''';
  static const _hooksPostGenContent = '''
import 'package:mason/mason.dart';

void run(HookContext context) {
  // TODO: add post-generation logic.
}
''';

  final String brickName;
  final String brickDescription;
  final bool createHooks;
}
