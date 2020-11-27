import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:mason/src/generator.dart';
import 'package:path/path.dart' as p;

import '../brick_yaml.dart';
import '../logger.dart';
import '../mason_yaml.dart';

/// {@template init_command}
/// `mason init` command which initializes a new `mason.yaml`.
/// {@endtemplate}
class InitCommand extends Command<dynamic> {
  /// {@macro init_command}
  InitCommand(this._logger);

  final Logger _logger;

  @override
  final String description = 'Initialize mason in the current directory.';

  @override
  final String name = 'init';

  Directory _cwd;

  /// Return the current working directory.
  Directory get cwd => _cwd ?? Directory.current;

  /// An override for the directory to generate into; public for testing.
  set cwd(Directory value) => _cwd = value;

  @override
  void run() async {
    final masonYaml = File(p.join(cwd.path, MasonYaml.file));
    if (masonYaml.existsSync()) {
      _logger.err('Existing ${MasonYaml.file} at ${masonYaml.path}');
      return;
    }
    final fetchDone = _logger.progress('Initializing');
    final target = DirectoryGeneratorTarget(cwd, _logger);
    final generator = _MasonYamlGenerator();
    await generator.generate(
      target,
      vars: <String, String>{'name': '{{name}}'},
    );
    fetchDone('Initialized');
    _logger
      ..info(
        '${lightGreen.wrap('✓')} Generated ${generator.files.length} file(s):',
      )
      ..flush(_logger.success);
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
