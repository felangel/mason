import 'package:mason/mason.dart';
import 'package:mason/src/command_runner.dart';
import 'package:mason/src/io.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  final cwd = Directory.current;

  group('mason add', () {
    late Logger logger;
    late MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      commandRunner = MasonCommandRunner(logger: logger);
      when(() => logger.progress(any())).thenReturn(([String? _]) {});
      setUpTestingEnvironment(cwd, suffix: '.add');

      File(path.join(Directory.current.path, 'mason.yaml'))
        ..writeAsStringSync('bricks:');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    group('local', () {
      test('exits with code 64 when brick is not provided', () async {
        final result = await commandRunner.run(
          ['add', '--source', 'path'],
        );
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err('path to the brick is required.')).called(1);
      });

      group('path', () {
        test('exits with code 64 when brick does not exist', () async {
          final result = await commandRunner.run(
            ['add', '--source', 'path', '.'],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(() => logger.err('brick not found at path .')).called(1);
        });

        test('adds brick successfully when brick exists', () async {
          final brickPath = path.join('..', '..', '..', 'bricks', 'greeting');
          final result = await commandRunner.run(
            ['add', '--source', 'path', brickPath],
          );
          expect(result, equals(ExitCode.success.code));
          final testDir = Directory(
            path.join(Directory.current.path, 'greeting'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(logger: logger).run(
            ['make', 'greeting', '--name', 'Dash'],
          );
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
          final brickPath = path.join('..', '..', '..', 'bricks', 'greeting');
          final result = await commandRunner.run(['add', brickPath]);
          expect(result, equals(ExitCode.success.code));
          final testDir = Directory(
            path.join(Directory.current.path, 'greeting'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(logger: logger).run(
            ['make', 'greeting', '--name', 'Dash'],
          );
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
          final result =
              await commandRunner.run(['add', '--source', 'git', url]);
          expect(result, equals(ExitCode.usage.code));
          verify(() => logger.err('brick not found at url $url')).called(1);
        });

        test('adds brick successfully when brick exists', () async {
          const url = 'https://github.com/felangel/mason';
          final result = await commandRunner.run(
            ['add', '--source', 'git', url, '--path', 'bricks/widget'],
          );
          expect(result, equals(ExitCode.success.code));
          final testDir = Directory(
            path.join(Directory.current.path, 'widget'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(logger: logger).run(
            ['make', 'widget', '--name', 'cat'],
          );
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
    });

    group('global', () {
      setUp(() {
        try {
          File(path.join(Directory.current.path, 'mason.yaml'))
              .deleteSync(recursive: true);
        } catch (_) {}
      });

      test('exits with code 64 when brick is not provided', () async {
        final result = await commandRunner.run(
          ['add', '-g', '--source', 'path'],
        );
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err('path to the brick is required.')).called(1);
      });

      group('path', () {
        test('exits with code 64 when brick does not exist', () async {
          final result = await commandRunner.run(
            ['add', '--global', '--source', 'path', '.'],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(() => logger.err('brick not found at path .')).called(1);
        });

        test('adds brick successfully when brick exists', () async {
          final brickPath = path.join('..', '..', '..', 'bricks', 'greeting');
          final result = await commandRunner.run(
            ['add', '-g', '--source', 'path', brickPath],
          );
          expect(result, equals(ExitCode.success.code));
          final testDir = Directory(
            path.join(Directory.current.path, 'greeting'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(logger: logger).run(
            ['make', 'greeting', '--name', 'Dash'],
          );
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
          final brickPath = path.join('..', '..', '..', 'bricks', 'greeting');
          final result = await commandRunner.run(['add', '-g', brickPath]);
          expect(result, equals(ExitCode.success.code));
          final testDir = Directory(
            path.join(Directory.current.path, 'greeting'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(logger: logger).run(
            ['make', 'greeting', '--name', 'Dash'],
          );
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
            ['add', '--global', '--source', 'git', url],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(() => logger.err('brick not found at url $url')).called(1);
        });

        test('adds brick successfully when brick exists', () async {
          const url = 'https://github.com/felangel/mason';
          final result = await commandRunner.run(
            ['add', '-g', '--source', 'git', url, '--path', 'bricks/widget'],
          );
          expect(result, equals(ExitCode.success.code));
          final testDir = Directory(
            path.join(Directory.current.path, 'widget'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;
          final makeResult = await MasonCommandRunner(logger: logger).run(
            ['make', 'widget', '--name', 'cat'],
          );
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
    });
  });
}
