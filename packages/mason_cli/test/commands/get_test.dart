import 'dart:convert';
import 'dart:io';

import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason/mason.dart' as mason show packageVersion;
import 'package:mason_cli/src/command.dart';
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

  group('mason get', () {
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
      setUpTestingEnvironment(cwd, suffix: '.get');

      File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  app_icon:
    path: ../../../../../bricks/app_icon
  documentation:
    path: ../../../../../bricks/documentation
  greeting:
    path: ../../../../../bricks/greeting
  simple:
    path: ../../../../../bricks/simple
  todos:
    path: ../../../../../bricks/todos
  widget:
    git:
      url: https://github.com/felangel/mason
      path: bricks/widget
      ref: 997bc878c93534fad17d965be7cafe948a1dbb53
''',
      );
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('creates .mason/brick.json and mason-lock.json when mason.yaml exists',
        () async {
      final expectedBrickJsonPath = path.join(
        Directory.current.path,
        '.mason',
        'bricks.json',
      );
      final expectedMasonLockJsonPath = path.join(
        Directory.current.path,
        'mason-lock.json',
      );
      var doneCallCount = 0;
      final progress = MockProgress();
      when(() => progress.complete(any())).thenAnswer((invocation) {
        doneCallCount++;
      });
      when(() => logger.progress(any())).thenReturn(progress);

      expect(File(expectedBrickJsonPath).existsSync(), isFalse);
      expect(File(expectedMasonLockJsonPath).existsSync(), isFalse);

      final result = await commandRunner.run(['get']);
      expect(result, equals(ExitCode.success.code));

      expect(File(expectedBrickJsonPath).existsSync(), isTrue);
      expect(File(expectedMasonLockJsonPath).existsSync(), isTrue);

      final bricksPath = path.join('..', '..', '..', '..', '..', 'bricks');
      final appIconPath = canonicalize(
        path.join(Directory.current.path, bricksPath, 'app_icon'),
      );
      final docPath = canonicalize(
        path.join(Directory.current.path, bricksPath, 'documentation'),
      );
      final greetingPath = canonicalize(
        path.join(Directory.current.path, bricksPath, 'greeting'),
      );
      final simplePath = canonicalize(
        path.join(Directory.current.path, bricksPath, 'simple'),
      );
      final todosPath = canonicalize(
        path.join(Directory.current.path, bricksPath, 'todos'),
      );
      final widgetPath = canonicalize(
        path.join(
          BricksJson.rootDir.path,
          'git',
          '''mason_aHR0cHM6Ly9naXRodWIuY29tL2ZlbGFuZ2VsL21hc29u_997bc878c93534fad17d965be7cafe948a1dbb53''',
          'bricks',
          'widget',
        ),
      );

      expect(
        File(expectedBrickJsonPath).readAsStringSync(),
        equals(
          json.encode({
            'app_icon': appIconPath,
            'documentation': docPath,
            'greeting': greetingPath,
            'simple': simplePath,
            'todos': todosPath,
            'widget': widgetPath,
          }),
        ),
      );
      expect(
        File(expectedMasonLockJsonPath).readAsStringSync(),
        equals(
          json.encode({
            'bricks': {
              'app_icon': {'path': appIconPath},
              'documentation': {'path': docPath},
              'greeting': {'path': greetingPath},
              'simple': {'path': simplePath},
              'todos': {'path': todosPath},
              'widget': {
                'git': {
                  'url': 'https://github.com/felangel/mason',
                  'path': 'bricks/widget',
                  'ref': '997bc878c93534fad17d965be7cafe948a1dbb53'
                }
              }
            }
          }),
        ),
      );

      verify(() => logger.progress('Getting bricks')).called(1);
      expect(doneCallCount, equals(1));
    });

    test('does not error when brick.json already exists', () async {
      final expectedBrickJsonPath = path.join(
        Directory.current.path,
        '.mason',
        'bricks.json',
      );

      final resultA = await commandRunner.run(['get']);
      expect(resultA, equals(ExitCode.success.code));

      final resultB = await commandRunner.run(['get']);
      expect(resultB, equals(ExitCode.success.code));

      expect(File(expectedBrickJsonPath).existsSync(), isTrue);
    });

    test('does not error when mason-lock.json already exists', () async {
      final expectedMasonLockJsonPath = path.join(
        Directory.current.path,
        'mason-lock.json',
      );

      final resultA = await commandRunner.run(['get']);
      expect(resultA, equals(ExitCode.success.code));

      final resultB = await commandRunner.run(['get']);
      expect(resultB, equals(ExitCode.success.code));

      expect(File(expectedMasonLockJsonPath).existsSync(), isTrue);
    });

    test('resolves git and hosted versions', () async {
      File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  hello: ^0.1.0-dev
  widget:
    git:
      url: https://github.com/felangel/mason
      path: bricks/widget
''',
      );
      final expectedMasonLockJsonPath = path.join(
        Directory.current.path,
        'mason-lock.json',
      );

      final resultA = await commandRunner.run(['get']);
      expect(resultA, equals(ExitCode.success.code));
      expect(File(expectedMasonLockJsonPath).existsSync(), isTrue);
      final lockA = File(expectedMasonLockJsonPath).readAsStringSync();

      final resultB = await commandRunner.run(['get']);
      expect(resultB, equals(ExitCode.success.code));
      expect(File(expectedMasonLockJsonPath).existsSync(), isTrue);
      final lockB = File(expectedMasonLockJsonPath).readAsStringSync();

      expect(lockA, equals(lockB));
    });

    test('exits with code 64 when mason.yaml does not exist', () async {
      Directory.current = cwd.path;
      final result = await commandRunner.run(['get']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err(const MasonYamlNotFoundException().message),
      ).called(1);
    });

    test('throws BrickNotFoundException when path does not exist', () async {
      File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  app_icon:
    path: ../../wrong/path  
''',
      );
      final result = await commandRunner.run(['get']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err(
          BrickNotFoundException(canonicalize('../../wrong/path')).message,
        ),
      ).called(1);
    });

    test('throws BrickNotFoundException when git path does not exist',
        () async {
      File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  widget:
    git:
      url: https://github.com/felangel/mason
      path: bricks/invalid
''',
      );
      final result = await commandRunner.run(['get']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err(
          const BrickNotFoundException(
            'https://github.com/felangel/mason/bricks/invalid',
          ).message,
        ),
      ).called(1);
    });

    test('throws MasonYamlParseException when mason.yaml is malformed',
        () async {
      File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
{malformed}
''',
      );
      final result = await commandRunner.run(['get']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err(
          any(
            that: contains(
              'Unrecognized keys: [malformed]; supported keys: [bricks]',
            ),
          ),
        ),
      ).called(1);
    });

    test(
        'throws MasonYamlNameMismatch '
        'when mason.yaml contains mismatch', () async {
      File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  app_icon1:
    path: ../../../../../bricks/app_icon
''',
      );
      commandRunner = MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
      const expectedErrorMessage =
          '''Brick name "app_icon1" doesn't match provided name "app_icon" in mason.yaml.''';
      final getResult = await commandRunner.run(['get']);
      expect(getResult, equals(ExitCode.usage.code));
      verify(() => logger.err(expectedErrorMessage)).called(1);
    });

    test('exits with code 64 when mason version constraint cannot be resolved',
        () async {
      await commandRunner.run(['new', 'example']);
      final brickYaml = File(path.join('example', 'brick.yaml'));
      brickYaml.writeAsStringSync(
        brickYaml.readAsStringSync().replaceFirst(
              'mason: ">=${mason.packageVersion} <0.1.0"',
              'mason: ">=99.99.99 <100.0.0"',
            ),
      );
      File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
  example:
    path:  ./example
''',
        mode: FileMode.append,
      );

      commandRunner = MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );

      final result = await commandRunner.run(['get']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err(
          '''The current mason version is ${mason.packageVersion}.\nBecause example requires mason version >=99.99.99 <100.0.0, version solving failed.''',
        ),
      ).called(1);
    });

    test('throws ProcessException when remote does not exist', () async {
      File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  widget:
    git:
      url: https://github.com/felangel/mason1
      path: bricks/invalid
''',
      );
      final result = await commandRunner.run(['get']);
      expect(result, equals(ExitCode.unavailable.code));
      verify(() => logger.err(any(that: contains('fatal:')))).called(1);
    });
  });
}
