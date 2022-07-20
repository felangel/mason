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

  group('mason new', () {
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
      setUpTestingEnvironment(cwd, suffix: '.new');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('exits with code 64 when name is missing', () async {
      File(path.join(Directory.current.path, 'mason.yaml'))
          .writeAsStringSync('bricks:\n');
      final result = await commandRunner.run(['new']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('Name of the new brick is required.')).called(1);
    });

    test(
        'exits with code 64 when '
        'exception occurs during generation', () async {
      final progress = MockProgress();
      when(() => progress.complete(any())).thenAnswer((invocation) {
        final update = invocation.positionalArguments[0] as String?;
        if (update?.startsWith('Created new brick:') == true) {
          throw const MasonException('oops');
        }
      });
      when(() => logger.progress(any())).thenReturn(progress);
      final result = await commandRunner.run(['new', 'hello world']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('oops')).called(1);
    });

    test('creates a new brick when it does not exist', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'simple'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run(['new', 'hello world']);
      expect(result, equals(ExitCode.success.code));
      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.new'), 'simple'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'new'), 'simple'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
      verify(() => logger.flush(any())).called(1);
    });

    test('creates a new brick w/custom output-dir', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'custom'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final outputDir = path.join(testDir.path, 'bricks');
      final result = await commandRunner.run(
        ['new', 'hello world', '-o', outputDir],
      );
      expect(result, equals(ExitCode.success.code));
      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.new'), 'custom'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'new'), 'custom'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
      verify(() => logger.flush(any())).called(1);
    });

    test('creates a new brick w/hooks', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'hooks'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run(['new', 'hooks', '--hooks']);
      expect(result, equals(ExitCode.success.code));
      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.new'), 'hooks'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'new'), 'hooks'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
      verify(() => logger.flush(any())).called(1);
    });

    test('exits with code 64 when brick already exists', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'simple'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run(['new', 'hello world']);
      expect(result, equals(ExitCode.success.code));
      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.new'), 'simple'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'new'), 'simple'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);

      final secondResult = await commandRunner.run(['new', 'hello world']);
      expect(secondResult, equals(ExitCode.usage.code));
      final expectedBrickPath = canonicalize(
        path.join(Directory.current.path, 'hello_world'),
      );
      verify(
        () => logger.err('Existing brick: hello_world at $expectedBrickPath'),
      ).called(1);
    });
  });
}
