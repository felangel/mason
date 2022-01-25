import 'package:mason/mason.dart';
import 'package:mason/src/generator.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Hooks', () {
    test(
        'throws HookInvalidCharactersException '
        'when containining non-ascii characters', () async {
      final brickYaml = BrickYaml(
        name: 'unicode_hook',
        description: 'A Test Hook',
        version: '1.0.0',
        path: path.join('test', 'fixtures', 'unicode_hook', 'brick.yaml'),
      );

      final generator = await MasonGenerator.fromBrickYaml(brickYaml);

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
      final brickYaml = BrickYaml(
        name: 'malformed_pubspec',
        description: 'A Test Hook',
        version: '1.0.0',
        path: path.join('test', 'fixtures', 'malformed_pubspec', 'brick.yaml'),
      );

      final generator = await MasonGenerator.fromBrickYaml(brickYaml);

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
      final brickYaml = BrickYaml(
        name: 'missing_run',
        description: 'A Test Hook',
        version: '1.0.0',
        path: path.join('test', 'fixtures', 'missing_run', 'brick.yaml'),
      );

      final generator = await MasonGenerator.fromBrickYaml(brickYaml);

      try {
        await generator.hooks.preGen();
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookMissingRunException>());
      }
    });

    test('throws HookRunException when hook cannot be run', () async {
      final brickYaml = BrickYaml(
        name: 'run_exception',
        description: 'A Test Hook',
        version: '1.0.0',
        path: path.join('test', 'fixtures', 'run_exception', 'brick.yaml'),
      );

      final generator = await MasonGenerator.fromBrickYaml(brickYaml);

      try {
        await generator.hooks.preGen();
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookRunException>());
      }
    });

    test('throws HookExecutionException when hook throws', () async {
      final brickYaml = BrickYaml(
        name: 'execution_exception',
        description: 'A Test Hook',
        version: '1.0.0',
        path: path.join(
          'test',
          'fixtures',
          'execution_exception',
          'brick.yaml',
        ),
      );

      final generator = await MasonGenerator.fromBrickYaml(brickYaml);

      try {
        await generator.hooks.preGen();
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookExecutionException>());
      }
    });
  });
}
