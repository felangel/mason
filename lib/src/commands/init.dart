import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/generator.dart';
import 'package:path/path.dart' as p;

import '../brick_yaml.dart';
import '../command.dart';
import '../mason_yaml.dart';

/// {@template init_command}
/// `mason init` command which initializes a new `mason.yaml`.
/// {@endtemplate}
class InitCommand extends MasonCommand {
  /// {@macro init_command}
  InitCommand({Logger logger}) : super(logger: logger);

  @override
  final String description = 'Initialize mason in the current directory.';

  @override
  final String name = 'init';

  @override
  Future<int> run() async {
    if (masonInitialized) {
      logger.err('Existing ${MasonYaml.file} at ${masonYamlFile.path}');
      return ExitCode.usage.code;
    }
    final fetchDone = logger.progress('Initializing');
    final target = DirectoryGeneratorTarget(cwd, logger);
    final generator = _MasonYamlGenerator();
    await generator.generate(
      target,
      vars: <String, String>{'name': '{{name}}'},
    );
    fetchDone('Initialized');
    logger
      ..info(
        '${lightGreen.wrap('✓')} Generated ${generator.files.length} file(s):',
      )
      ..flush(logger.success);
    return ExitCode.success.code;
  }
}

class _MasonYamlGenerator extends MasonGenerator {
  _MasonYamlGenerator()
      : super(
          '__mason_init__',
          'Initialize a new ${MasonYaml.file}',
          files: [
            TemplateFile(MasonYaml.file, _masonYamlContent),
            TemplateFile(
              p.join('bricks', 'hello', BrickYaml.file),
              _brickYamlContent,
            ),
            TemplateFile(
              p.join('bricks', 'hello', BrickYaml.dir, 'HELLO.md'),
              'Hello {{name}}!',
            ),
          ],
        );

  static const _brickYamlContent = '''name: hello
description: An example hello brick.
vars:
  - name
''';

  static const _masonYamlContent =
      '''# Register bricks which can be consumed via the Mason CLI.
# https://pub.dev/packages/mason
bricks:
  # Sample Brick
  # Run `mason make hello` to try it out.
  hello:
    path: bricks/hello
  # Bricks can also be imported via git url.
  # Uncomment the following lines to import
  # a brick from a remote git url.
  # todos:
  #   git:
  #     url: git@github.com:felangel/mason.git
  #     path: bricks/todos
''';
}
