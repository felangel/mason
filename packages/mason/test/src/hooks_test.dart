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
        path.join('test', 'fixtures', 'compile_exception'),
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
        path.join('test', 'fixtures', 'compile_exception'),
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

    test('throws HookExecutionException on IsolateSpawnException', () async {
      final hookDirectoryPath = path.join('test', 'fixtures', 'basic', 'hooks');
      final files = [
        File(
          canonicalize(
            path.join(
              hookDirectoryPath,
              'pre_gen.dart',
            ),
          ),
        ),
        File(
          canonicalize(
            path.join(
              hookDirectoryPath,
              'build',
              'hooks',
              'pre_gen',
              'pre_gen_4eda2b9684fa8a724e89999f292f9f40e1a444cc.dart',
            ),
          ),
        ),
        File(
          canonicalize(
            path.join(
              hookDirectoryPath,
              'build',
              'hooks',
              'pre_gen',
              'pre_gen_504cde6a6747442973ca41234b44dd7d38d3778f.dart',
            ),
          ),
        ),
        File(
          canonicalize(
            path.join(
              hookDirectoryPath,
              '.dart_tool',
              'package_config.json',
            ),
          ),
        ),
        File(
          canonicalize(
            path.join(
              '.dart_tool',
              'package_config.json',
            ),
          ),
        ),
      ];

      final tempFile = File('.tmp.dill');
      final hooksDartToolDirectory = Directory(
        path.join('test', 'fixtures', 'basic', 'hooks', '.dart_tool'),
      );
      final hooksBuildDirectory = Directory(
        path.join('test', 'fixtures', 'basic', 'hooks', 'build', 'hooks'),
      );

      try {
        await hooksDartToolDirectory.delete(recursive: true);
      } catch (_) {}
      try {
        await hooksBuildDirectory.delete(recursive: true);
      } catch (_) {}

      final brick = Brick.path(path.join('test', 'fixtures', 'basic'));
      final generator = await MasonGenerator.fromBrick(brick);
      await IOOverrides.runZoned(
        () async {
          // 1st time, fresh run should not retry
          try {
            await generator.hooks.preGen();
            fail('should throw');
          } catch (error) {
            expect(error, isA<HookExecutionException>());
          }
          // 2nd time, stale run should retry
          try {
            await generator.hooks.preGen();
            fail('should throw');
          } catch (error) {
            expect(error, isA<HookExecutionException>());
          }
        },
        createFile: (p) {
          return files.firstWhere(
            (f) => path.equals(p, f.path),
            orElse: () => tempFile,
          );
        },
      );
      try {
        tempFile.deleteSync();
      } catch (_) {}
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

    test('compile installs dependencies and compiles hooks only once',
        () async {
      final hooksBuildDirectory = Directory(
        path.join('test', 'fixtures', 'basic', 'hooks', 'build', 'hooks'),
      );
      try {
        await hooksBuildDirectory.delete(recursive: true);
      } catch (_) {}

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
      final hooksBuildDirectory = Directory(
        path.join(
          'test',
          'fixtures',
          'relative_imports',
          'hooks',
          'build',
          'hooks',
        ),
      );
      final preGenHookBuildDirectory = Directory(
        path.join(hooksBuildDirectory.path, 'pre_gen'),
      );
      final postGenHookBuildDirectory = Directory(
        path.join(hooksBuildDirectory.path, 'post_gen'),
      );

      try {
        await hooksBuildDirectory.delete(recursive: true);
      } catch (_) {}

      expect(hooksBuildDirectory.existsSync(), isFalse);

      final brick = Brick.path(
        path.join('test', 'fixtures', 'relative_imports'),
      );
      final generator = await MasonGenerator.fromBrick(brick);
      await generator.hooks.preGen(
        vars: <String, dynamic>{'name': name},
        workingDirectory: directory.path,
      );
      final preGenOutput = File(path.join(directory.path, '.pre_gen.txt'));
      expect(preGenOutput.existsSync(), isTrue);
      expect(preGenOutput.readAsStringSync(), equals('pre_gen: $name'));
      expect(hooksBuildDirectory.existsSync(), isTrue);
      expect(preGenHookBuildDirectory.existsSync(), isTrue);
      expect(postGenHookBuildDirectory.existsSync(), isFalse);

      await generator.hooks.postGen(
        vars: <String, dynamic>{'name': name},
        workingDirectory: directory.path,
      );
      final postGenOutput = File(path.join(directory.path, '.post_gen.txt'));
      expect(postGenOutput.existsSync(), isTrue);
      expect(postGenOutput.readAsStringSync(), equals('post_gen: $name'));
      expect(preGenHookBuildDirectory.existsSync(), isTrue);
      expect(postGenHookBuildDirectory.existsSync(), isTrue);
    });

    test('recompiles hooks when an IsolateSpawnException occurs', () async {
      const name = 'Dash';
      final directory = Directory.systemTemp.createTempSync();
      final hooksBuildDirectory = Directory(
        path.join(
          'test',
          'fixtures',
          'relative_imports',
          'hooks',
          'build',
          'hooks',
        ),
      );
      final preGenHookBuildDirectory = Directory(
        path.join(hooksBuildDirectory.path, 'pre_gen'),
      );
      final postGenHookBuildDirectory = Directory(
        path.join(hooksBuildDirectory.path, 'post_gen'),
      );

      try {
        await hooksBuildDirectory.delete(recursive: true);
      } catch (_) {}

      expect(hooksBuildDirectory.existsSync(), isFalse);

      final brick = Brick.path(
        path.join('test', 'fixtures', 'relative_imports'),
      );
      final generator = await MasonGenerator.fromBrick(brick);

      await generator.hooks.preGen(
        vars: <String, dynamic>{'name': name},
        workingDirectory: directory.path,
      );
      final preGenOutput = File(path.join(directory.path, '.pre_gen.txt'));
      expect(preGenOutput.existsSync(), isTrue);
      expect(preGenOutput.readAsStringSync(), equals('pre_gen: $name'));
      expect(hooksBuildDirectory.existsSync(), isTrue);
      expect(preGenHookBuildDirectory.existsSync(), isTrue);
      expect(postGenHookBuildDirectory.existsSync(), isFalse);

      await generator.hooks.postGen(
        vars: <String, dynamic>{'name': name},
        workingDirectory: directory.path,
      );
      final postGenOutput = File(path.join(directory.path, '.post_gen.txt'));
      expect(postGenOutput.existsSync(), isTrue);
      expect(postGenOutput.readAsStringSync(), equals('post_gen: $name'));
      expect(preGenHookBuildDirectory.existsSync(), isTrue);
      expect(postGenHookBuildDirectory.existsSync(), isTrue);

      File? preGenModule;
      File? postGenModule;
      final legacyPreGen = File(
        path.join(
          'test',
          'fixtures',
          'relative_imports',
          'hooks',
          'legacy',
          'pre_gen.dill',
        ),
      );
      final legacyPostGen = File(
        path.join(
          'test',
          'fixtures',
          'relative_imports',
          'hooks',
          'legacy',
          'post_gen.dill',
        ),
      );
      final legacyPreGenBytes = legacyPreGen.readAsBytesSync();
      final legacyPostGenBytes = legacyPostGen.readAsBytesSync();
      final files =
          hooksBuildDirectory.listSync(recursive: true).whereType<File>();
      for (final file in files) {
        if (path.basenameWithoutExtension(file.path).startsWith('pre_gen_')) {
          preGenModule = file;
          file.writeAsBytesSync(legacyPreGenBytes);
        }
        if (path.basenameWithoutExtension(file.path).startsWith('post_gen_')) {
          postGenModule = file;
          file.writeAsBytesSync(legacyPostGenBytes);
        }
      }

      await generator.hooks.preGen(
        vars: <String, dynamic>{'name': name},
        workingDirectory: directory.path,
      );
      await generator.hooks.postGen(
        vars: <String, dynamic>{'name': name},
        workingDirectory: directory.path,
      );

      expect(
        preGenModule!.readAsBytesSync(),
        isNot(equals(legacyPreGenBytes)),
      );
      expect(
        postGenModule!.readAsBytesSync(),
        isNot(equals(legacyPostGenBytes)),
      );
    });
  });
}
