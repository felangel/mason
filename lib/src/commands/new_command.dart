import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:io/ansi.dart';
import 'package:mason/src/generator.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';

import '../brick_yaml.dart';
import '../logger.dart';
import '../mason_yaml.dart';
import '../yaml_encode.dart';

/// {@template new_command}
/// `mason new` command which creates a new brick.
/// {@endtemplate}
class NewCommand extends Command<dynamic> {
  /// {@macro new_command}
  NewCommand(this._logger) {
    argParser.addOption(
      'desc',
      abbr: 'd',
      help: 'Description of the new brick template',
      defaultsTo: 'A new brick created with the Mason CLI.',
    );
  }

  final Logger _logger;

  @override
  final String description = 'Creates a new brick template.';

  @override
  final String name = 'new';

  Directory _cwd;

  /// Return the current working directory.
  Directory get cwd => _cwd ?? Directory.current;

  /// An override for the directory to generate into; public for testing.
  set cwd(Directory value) => _cwd = value;

  @override
  void run() async {
    final name = argResults.rest.first.snakeCase;
    final description = argResults['desc'] as String;
    final masonYamlFile = MasonYaml.findNearest(cwd);
    if (masonYamlFile == null) {
      _logger.err(
        '''Cannot find ${MasonYaml.file}.\nDid you forget to run mason init?''',
      );
      return;
    }
    final directory = Directory(p.join(masonYamlFile.parent.path, 'bricks'));
    final brickYaml = File(
      p.join(directory.path, name, BrickYaml.file),
    );
    if (brickYaml.existsSync()) {
      _logger.err('Existing brick: $name at ${brickYaml.path}');
      return;
    }
    final done = _logger.progress('Creating new brick: $name.');
    final target = DirectoryGeneratorTarget(directory, _logger);
    final generator = _BrickGenerator(name, description);
    final masonYamlContent = masonYamlFile.readAsStringSync();
    final masonYaml = checkedYamlDecode(
      masonYamlContent,
      (m) => MasonYaml.fromJson(m),
    );
    final bricks = Map.of(masonYaml.bricks)
      ..addAll({
        name: Brick(
          path: p.relative(
            brickYaml.parent.path,
            from: masonYamlFile.parent.path,
          ),
        )
      });
    await Future.wait([
      generator.generate(target, vars: <String, dynamic>{'name': '{{name}}'}),
      if (!masonYaml.bricks.containsKey(name))
        masonYamlFile.writeAsString(Yaml.encode(MasonYaml(bricks).toJson())),
    ]);
    done('Created new brick: $name');
    _logger
      ..info(
        '${lightGreen.wrap('✓')} Generated ${generator.files.length} file(s):',
      )
      ..flush(_logger.success);
  }
}

class _BrickGenerator extends MasonGenerator {
  _BrickGenerator(this.brickName, this.brickDescription)
      : super(
          '__new_brick__',
          'Creates a new brick.',
          files: [
            TemplateFile(
              p.join(brickName, BrickYaml.file),
              _content(brickName, brickDescription),
            ),
            TemplateFile(
              p.join(brickName, BrickYaml.dir, 'hello.md'),
              'Hello {{name}}!',
            ),
          ],
        );

  static String _content(String name, String description) => '''name: $name
description: $description
vars:
  - name
''';

  final String brickName;
  final String brickDescription;
}
