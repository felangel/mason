import 'dart:io';

import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_cli/src/command_runner.dart';
import 'package:mason_cli/src/version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

class MockProgress extends Mock implements Progress {}

void main() {
  final cwd = Directory.current;

  group('mason add', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      pubUpdater = MockPubUpdater();

      when(() => logger.progress(any())).thenReturn(MockProgress());
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      commandRunner = MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
      setUpTestingEnvironment(cwd, suffix: '.add');

      File(
        path.join(Directory.current.path, 'mason.yaml'),
      ).writeAsStringSync('bricks:');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('exits with code 64 when bricks.json does not exist', () async {
      Directory.current = Directory.systemTemp.createTempSync();
      final result = await commandRunner.run(['add', 'example', '--path', '.']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('bricks.json not found')).called(1);
    });

    test('exits with code 64 when exception occurs', () async {
      final progress = MockProgress();
      when(() => progress.complete(any())).thenAnswer((invocation) {
        final update = invocation.positionalArguments[0] as String?;

        if (update?.startsWith('Added') == true) {
          throw const MasonException('oops');
        }
      });
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenThrow(Exception());
      when(() => logger.progress(any())).thenReturn(progress);
      final brickPath =
          path.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
      final result = await commandRunner.run(
        ['add', 'greeting', '--path', brickPath],
      );
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.progress('Installing greeting')).called(1);
      verify(() => logger.err('oops')).called(1);
    });

    test('exits with code 70 on hook compilation exception', () async {
      final progress = MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      final brickPath = path.join('..', '..', 'bricks', 'compilation_error');
      final result = await commandRunner.run(
        ['add', 'compilation_error', '--path', brickPath],
      );
      expect(result, equals(ExitCode.usage.code));
      verify(progress.fail).called(1);
    });

    group('local', () {
      test('exits with code 64 when brick is not provided', () async {
        final result = await commandRunner.run(['add']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err('brick name is required.')).called(1);
      });

      group('path', () {
        test('exits with code 64 when brick does not exist', () async {
          final result = await commandRunner.run(
            ['add', 'example', '--path', '.'],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(
            () => logger.err(
              '''Could not find brick at ${canonicalize(Directory.current.path)}''',
            ),
          ).called(1);
        });

        test('exits with code 64 when name does not match', () async {
          final brickPath =
              path.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
          final result = await commandRunner.run(
            ['add', 'example', '--path', brickPath],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(() => logger.progress('Installing example')).called(1);
          verify(
            () => logger.err(
              '''Brick name "example" doesn't match provided name "greeting" in mason.yaml.''',
            ),
          ).called(1);
        });

        test('adds brick successfully when brick exists', () async {
          final brickPath =
              path.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
          final result = await commandRunner.run(
            ['add', 'greeting', '--path', brickPath],
          );
          expect(result, equals(ExitCode.success.code));
          final testDir = Directory(
            path.join(Directory.current.path, 'greeting'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(
            logger: logger,
            pubUpdater: pubUpdater,
          ).run(['make', 'greeting', '--name', 'Dash']);
          expect(makeResult, equals(ExitCode.success.code));

          verify(() => logger.progress('Installing greeting')).called(1);

          final actual = Directory(
            path.join(testFixturesPath(cwd, suffix: '.add'), 'greeting'),
          );
          final expected = Directory(
            path.join(testFixturesPath(cwd, suffix: 'add'), 'greeting'),
          );
          expect(directoriesDeepEqual(actual, expected), isTrue);
        });

        test(
            'adds brick successfully when brick exists '
            'from nested directory', () async {
          final nested = Directory(path.join(Directory.current.path, 'nested'))
            ..createSync();
          final workspace = Directory.current;
          Directory.current = nested;
          final brickPath = path.join(
            '..',
            '..',
            '..',
            '..',
            '..',
            '..',
            'bricks',
            'greeting',
          );
          final result = await commandRunner.run(
            ['add', 'greeting', '--path', brickPath],
          );
          expect(result, equals(ExitCode.success.code));
          Directory.current = workspace;
          final testDir = Directory(
            path.join(Directory.current.path, 'greeting'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(
            logger: logger,
            pubUpdater: pubUpdater,
          ).run(['make', 'greeting', '--name', 'Dash']);
          expect(makeResult, equals(ExitCode.success.code));

          verify(() => logger.progress('Installing greeting')).called(1);

          final actual = Directory(
            path.join(testFixturesPath(cwd, suffix: '.add'), 'greeting'),
          );
          final expected = Directory(
            path.join(testFixturesPath(cwd, suffix: 'add'), 'greeting'),
          );
          expect(directoriesDeepEqual(actual, expected), isTrue);
        });
      });

      group('git', () {
        test('exits with code 64 when brick does not exist', () async {
          const url = 'https://github.com/felangel/mason';
          final result = await commandRunner.run(
            ['add', 'example', '--git-url', url],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(() => logger.err('Could not find brick at $url')).called(1);
        });

        test('exits with code 64 when brick does not exist (path)', () async {
          const url = 'https://github.com/felangel/mason';
          const path = 'bricks/example';
          final result = await commandRunner.run(
            ['add', 'example', '--git-url', url, '--git-path', path],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(
            () => logger.err('Could not find brick at $url/$path'),
          ).called(1);
        });

        test('exits with code 64 when name does not match', () async {
          const url = 'https://github.com/felangel/mason';
          final result = await commandRunner.run(
            ['add', 'example', '--git-url', url, '--git-path', 'bricks/widget'],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(
            () => logger.err(
              '''Brick name "example" doesn't match provided name "widget" in mason.yaml.''',
            ),
          ).called(1);
        });

        test('adds brick successfully when brick exists', () async {
          const url = 'https://github.com/felangel/mason';
          final result = await commandRunner.run(
            ['add', 'widget', '--git-url', url, '--git-path', 'bricks/widget'],
          );
          expect(result, equals(ExitCode.success.code));
          final testDir = Directory(
            path.join(Directory.current.path, 'widget'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(
            logger: logger,
            pubUpdater: pubUpdater,
          ).run(['make', 'widget', '--name', 'cat']);
          expect(makeResult, equals(ExitCode.success.code));

          final actual = Directory(
            path.join(testFixturesPath(cwd, suffix: '.add'), 'widget'),
          );
          final expected = Directory(
            path.join(testFixturesPath(cwd, suffix: 'add'), 'widget'),
          );
          expect(directoriesDeepEqual(actual, expected), isTrue);
        });
      });

      group('registry', () {
        test('exits with code 64 when brick does not exist', () async {
          final result = await commandRunner.run(['add', 'nonexistent-brick']);
          expect(result, equals(ExitCode.usage.code));
          verify(
            () => logger.err('Brick "nonexistent-brick" does not exist.'),
          ).called(1);
        });

        test('exits with code 64 when too many arguments provided', () async {
          final result = await commandRunner.run(
            ['add', 'nonexistent-brick', 'foo', 'bar'],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(
            () => logger.err(
              'Too many arguments, expected arguments <name> <version>',
            ),
          ).called(1);
        });

        test('adds brick successfully when brick exists', () async {
          final result = await commandRunner.run(['add', 'greeting']);
          expect(result, equals(ExitCode.success.code));
          final testDir = Directory(
            path.join(Directory.current.path, 'greeting'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(
            logger: logger,
            pubUpdater: pubUpdater,
          ).run(['make', 'greeting', '--name', 'Dash']);
          expect(makeResult, equals(ExitCode.success.code));

          final actual = Directory(
            path.join(testFixturesPath(cwd, suffix: '.add'), 'greeting'),
          );
          final expected = Directory(
            path.join(testFixturesPath(cwd, suffix: 'add'), 'greeting'),
          );
          expect(directoriesDeepEqual(actual, expected), isTrue);
        });

        test('adds brick successfully when brick exists w/version', () async {
          final addResult = await commandRunner.run(
            ['add', 'greeting', '0.1.0+1'],
          );
          expect(addResult, equals(ExitCode.success.code));

          final listResult = await commandRunner.run(['ls']);
          expect(listResult, equals(ExitCode.success.code));
          verify(
            () => logger.info(
              any(
                that: contains(
                  '''${styleBold.wrap('greeting')} 0.1.0+1 -> registry.brickhub.dev''',
                ),
              ),
            ),
          ).called(1);
        });
      });
    });

    group('global', () {
      setUp(() {
        try {
          File(path.join(Directory.current.path, 'mason.yaml'))
              .deleteSync(recursive: true);
        } catch (_) {}
      });

      test('exits with code 64 when brick is not provided', () async {
        final result = await commandRunner.run(['add', '-g']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err('brick name is required.')).called(1);
      });

      group('path', () {
        test('exits with code 64 when brick does not exist', () async {
          final result = await commandRunner.run(
            ['add', '--global', 'example', '--path', '.'],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(
            () => logger.err(
              '''Could not find brick at ${canonicalize(Directory.current.path)}''',
            ),
          ).called(1);
        });

        test('adds brick successfully when brick exists', () async {
          final brickPath =
              path.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
          final result = await commandRunner.run(
            ['add', '--global', 'greeting', '--path', brickPath],
          );
          expect(result, equals(ExitCode.success.code));
          final testDir = Directory(
            path.join(Directory.current.path, 'greeting'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(
            logger: logger,
            pubUpdater: pubUpdater,
          ).run(['make', 'greeting', '--name', 'Dash']);
          expect(makeResult, equals(ExitCode.success.code));

          final actual = Directory(
            path.join(testFixturesPath(cwd, suffix: '.add'), 'greeting'),
          );
          final expected = Directory(
            path.join(testFixturesPath(cwd, suffix: 'add'), 'greeting'),
          );
          expect(directoriesDeepEqual(actual, expected), isTrue);
        });

        test('adds brick successfully when brick exists (shorthand)', () async {
          final brickPath =
              path.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
          final result = await commandRunner.run(
            ['add', '-g', 'greeting', '--path', brickPath],
          );
          expect(result, equals(ExitCode.success.code));
          final testDir = Directory(
            path.join(Directory.current.path, 'greeting'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(
            logger: logger,
            pubUpdater: pubUpdater,
          ).run(['make', 'greeting', '--name', 'Dash']);
          expect(makeResult, equals(ExitCode.success.code));

          final actual = Directory(
            path.join(testFixturesPath(cwd, suffix: '.add'), 'greeting'),
          );
          final expected = Directory(
            path.join(testFixturesPath(cwd, suffix: 'add'), 'greeting'),
          );
          expect(directoriesDeepEqual(actual, expected), isTrue);
        });
      });

      group('git', () {
        test('exits with code 64 when brick does not exist', () async {
          const url = 'https://github.com/felangel/mason';
          final result = await commandRunner.run(
            ['add', '--global', 'example', '--git-url', url],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(() => logger.err('Could not find brick at $url')).called(1);
        });

        test('adds brick successfully when brick exists', () async {
          const url = 'https://github.com/felangel/mason';
          final result = await commandRunner.run(
            [
              'add',
              '-g',
              'widget',
              '--git-url',
              url,
              '--git-path',
              'bricks/widget'
            ],
          );
          expect(result, equals(ExitCode.success.code));
          final testDir = Directory(
            path.join(Directory.current.path, 'widget'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(
            logger: logger,
            pubUpdater: pubUpdater,
          ).run(['make', 'widget', '--name', 'cat']);
          expect(makeResult, equals(ExitCode.success.code));

          final actual = Directory(
            path.join(testFixturesPath(cwd, suffix: '.add'), 'widget'),
          );
          final expected = Directory(
            path.join(testFixturesPath(cwd, suffix: 'add'), 'widget'),
          );
          expect(directoriesDeepEqual(actual, expected), isTrue);
        });
      });

      group('registry', () {
        test('exits with code 64 when brick does not exist', () async {
          final result = await commandRunner.run(
            ['add', '-g', 'nonexistent-brick'],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(
            () => logger.err('Brick "nonexistent-brick" does not exist.'),
          ).called(1);
        });

        test('exits with code 64 when too many arguments provided', () async {
          final result = await commandRunner.run(
            ['add', '-g', 'nonexistent-brick', 'foo', 'bar'],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(
            () => logger.err(
              'Too many arguments, expected arguments <name> <version>',
            ),
          ).called(1);
        });

        test('adds brick successfully when brick exists', () async {
          final result = await commandRunner.run(['add', '-g', 'greeting']);
          expect(result, equals(ExitCode.success.code));
          final testDir = Directory(
            path.join(Directory.current.path, 'greeting'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(
            logger: logger,
            pubUpdater: pubUpdater,
          ).run(['make', 'greeting', '--name', 'Dash']);
          expect(makeResult, equals(ExitCode.success.code));

          final actual = Directory(
            path.join(testFixturesPath(cwd, suffix: '.add'), 'greeting'),
          );
          final expected = Directory(
            path.join(testFixturesPath(cwd, suffix: 'add'), 'greeting'),
          );
          expect(directoriesDeepEqual(actual, expected), isTrue);
        });

        test('adds brick successfully when brick exists w/version', () async {
          final addResult = await commandRunner.run(
            ['add', '-g', 'greeting', '0.1.0+1'],
          );
          expect(addResult, equals(ExitCode.success.code));

          final listResult = await commandRunner.run(['ls', '-g']);
          expect(listResult, equals(ExitCode.success.code));
          verify(
            () => logger.info(
              any(
                that: contains(
                  '''${styleBold.wrap('greeting')} 0.1.0+1 -> registry.brickhub.dev''',
                ),
              ),
            ),
          ).called(1);
        });
      });
    });
  });
}
