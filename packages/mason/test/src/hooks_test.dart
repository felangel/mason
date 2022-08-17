import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mason/src/generator.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Hooks', () {
    test(
        'throws HookDependencyInstallFailure '
        'when pubspec is malformed', () async {
      final brick = Brick.path(
        path.join('test', 'fixtures', 'malformed_pubspec'),
      );
      final generator = await MasonGenerator.fromBrick(brick);

      try {
        await generator.hooks.preGen();
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookDependencyInstallFailure>());
      }
    });

    test(
        'throws HookMissingRunException '
        'when hook does not contain a valid run method', () async {
      final brick = Brick.path(
        path.join('test', 'fixtures', 'missing_run'),
      );
      final generator = await MasonGenerator.fromBrick(brick);

      try {
        await generator.hooks.preGen();
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookMissingRunException>());
      }
    });

    test('throws HookRunException when hook cannot be run', () async {
      final brick = Brick.path(
        path.join('test', 'fixtures', 'run_exception'),
      );
      final generator = await MasonGenerator.fromBrick(brick);

      try {
        await generator.hooks.preGen();
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookRunException>());
      }
    });

    test('throws HookExecutionException when hook throws', () async {
      final brick = Brick.path(
        path.join('test', 'fixtures', 'execution_exception'),
      );
      final generator = await MasonGenerator.fromBrick(brick);

      try {
        await generator.hooks.preGen();
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookExecutionException>());
      }
    });

    test('supports relative imports within hooks', () async {
      const name = 'Dash';
      final directory = Directory.systemTemp.createTempSync();
      final brick = Brick.path(
        path.join('test', 'fixtures', 'relative_imports_hook'),
      );
      final generator = await MasonGenerator.fromBrick(brick);
      await generator.hooks.preGen(
        vars: <String, dynamic>{'name': name},
        workingDirectory: directory.path,
      );
      final file = File(path.join(directory.path, '.pre_gen.txt'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), equals('pre_gen: $name'));
    });
  });
}
