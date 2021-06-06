import 'dart:io';

import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/command_runner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  final cwd = Directory.current;

  group('mason install', () {
    late Logger logger;
    late MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      commandRunner = MasonCommandRunner(logger: logger);
      when(() => logger.progress(any())).thenReturn(([String? _]) {});
      setUpTestingEnvironment(cwd, suffix: '.install');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('exits with code 64 when brick is not provided', () async {
      final result = await commandRunner.run(
        ['install', '--source', 'path'],
      );
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('path to the brick is required.')).called(1);
    });

    group('path', () {
      test('exits with code 64 when brick does not exist', () async {
        final result = await commandRunner.run(
          ['install', '--source', 'path', '.'],
        );
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err('brick not found at path .')).called(1);
      });

      test('installs brick successfully when brick exists', () async {
        final brickPath = path.join('..', '..', '..', 'bricks', 'greeting');
        final result = await commandRunner.run(
          ['install', '--source', 'path', brickPath],
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
          path.join(testFixturesPath(cwd, suffix: '.install'), 'greeting'),
        );
        final expected = Directory(
          path.join(testFixturesPath(cwd, suffix: 'install'), 'greeting'),
        );
        expect(directoriesDeepEqual(actual, expected), isTrue);
      });
    });

    group('git', () {
      test('exits with code 64 when brick does not exist', () async {
        const url = 'https://github.com/felangel/mason';
        final result = await commandRunner.run(['install', url]);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err('brick not found at url $url')).called(1);
      });

      test('installs brick successfully when brick exists', () async {
        const url = 'https://github.com/felangel/mason';
        final result = await commandRunner.run(
          ['install', url, '--path', 'bricks/widget'],
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
          path.join(testFixturesPath(cwd, suffix: '.install'), 'widget'),
        );
        final expected = Directory(
          path.join(testFixturesPath(cwd, suffix: 'install'), 'widget'),
        );
        expect(directoriesDeepEqual(actual, expected), isTrue);
      });
    });
  });
}
