import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mason/src/generator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

void main() {
  group('Hooks', () {
    setUp(() async {
      try {
        await BricksJson.hooksDir.delete(recursive: true);
      } catch (_) {}
    });

    test('supports non-ascii characters', () async {
      final brick = Brick.path(
        path.join('test', 'fixtures', 'unicode_hook'),
      );
      final generator = await MasonGenerator.fromBrick(brick);

      expect(generator.hooks.preGen(), completes);
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
        'throws HookCompileException '
        'when unable to resolve a type', () async {
      final brick = Brick.path(
        path.join('test', 'fixtures', 'spawn_exception'),
      );
      final generator = await MasonGenerator.fromBrick(brick);

      try {
        await generator.hooks.preGen();
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookCompileException>());
      }
    });

    test(
        'throws HookCompileException '
        'when unable to resolve a type (back-to-back)', () async {
      final brick = Brick.path(
        path.join('test', 'fixtures', 'spawn_exception'),
      );
      final generator = await MasonGenerator.fromBrick(brick);

      try {
        await generator.hooks.preGen();
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookCompileException>());
      }

      try {
        await generator.hooks.preGen();
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookCompileException>());
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

    test('throws HookCompileException when hook cannot be run', () async {
      final brick = Brick.path(
        path.join('test', 'fixtures', 'run_exception'),
      );
      final generator = await MasonGenerator.fromBrick(brick);

      try {
        await generator.hooks.preGen();
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookCompileException>());
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

    test(
        'throws HookDependencyInstallFailure '
        'when dependencies cannot be resolved', () async {
      final brick = Brick.path(
        path.join('test', 'fixtures', 'dependency_install_failure'),
      );
      final generator = await MasonGenerator.fromBrick(brick);

      try {
        await generator.hooks.preGen();
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookDependencyInstallFailure>());
      }
    });

    test('installs dependencies and compiles hooks only once', () async {
      final brick = Brick.path(path.join('test', 'fixtures', 'basic'));
      final generator = await MasonGenerator.fromBrick(brick);
      final logger = _MockLogger();
      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);

      await expectLater(generator.hooks.compile(logger: logger), completes);

      verify(() => logger.progress('Compiling pre_gen.dart')).called(1);
      verify(() => progress.complete('Compiled pre_gen.dart')).called(1);
      verify(() => logger.progress('Compiling post_gen.dart')).called(1);
      verify(() => progress.complete('Compiled post_gen.dart')).called(1);

      await expectLater(generator.hooks.compile(logger: logger), completes);

      verifyNever(() => logger.progress('Compiling pre_gen.dart'));
      verifyNever(() => progress.complete('Compiled pre_gen.dart'));
      verifyNever(() => logger.progress('Compiling post_gen.dart'));
      verifyNever(() => progress.complete('Compiled post_gen.dart'));
    });

    test('compile reports compilation errors', () async {
      final brick = Brick.path(
        path.join('test', 'fixtures', 'run_exception'),
      );
      final generator = await MasonGenerator.fromBrick(brick);
      final logger = _MockLogger();
      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);

      try {
        await generator.hooks.compile(logger: logger);
        fail('should throw');
      } catch (error) {
        expect(error, isA<HookCompileException>());
      }
      verify(() => logger.progress('Compiling pre_gen.dart')).called(1);
      verify(
        () => progress.fail(
          any(that: contains("Error: Expected '{' before this.")),
        ),
      ).called(1);
    });

    test('recovers from cleared pub cache', () async {
      final brick = Brick.path(path.join('test', 'fixtures', 'basic'));
      final generator = await MasonGenerator.fromBrick(brick);

      await expectLater(generator.hooks.preGen(), completes);

      final result = await Process.run('dart', ['pub', 'cache', 'clean']);
      expect(result.exitCode, equals(ExitCode.success.code));

      await expectLater(generator.hooks.preGen(), completes);
    });

    test('supports relative imports within hooks', () async {
      const name = 'Dash';
      final directory = Directory.systemTemp.createTempSync();
      final brick = Brick.path(
        path.join('test', 'fixtures', 'relative_imports'),
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
