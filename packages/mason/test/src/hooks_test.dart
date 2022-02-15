import 'package:mason/mason.dart';
import 'package:mason/src/generator.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Hooks', () {
    test(
        'throws HookInvalidCharactersException '
        'when containining non-ascii characters', () async {
      final brick = Brick.path(
        path.join('test', 'fixtures', 'unicode_hook'),
      );
      final generator = await MasonGenerator.fromBrick(brick);

      try {
        await generator.hooks.preGen();
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookInvalidCharactersException>());
      }
    });

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
  });
}
