import 'dart:convert';

import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/command_runner.dart';
import 'package:mason_cli/src/version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

void main() {
  final cwd = Directory.current;

  group('mason get', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      pubUpdater = MockPubUpdater();

      when(() => logger.progress(any())).thenReturn(([String? _]) {});
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
''',
      );
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('creates .mason/brick.json when mason.yaml exists', () async {
      final expectedBrickJsonPath = path.join(
        Directory.current.path,
        '.mason',
        'bricks.json',
      );
      var doneCallCount = 0;
      when(() => logger.progress(any())).thenReturn(
        ([String? _]) => doneCallCount++,
      );

      expect(File(expectedBrickJsonPath).existsSync(), isFalse);

      final result = await commandRunner.run(['get']);
      expect(result, equals(ExitCode.success.code));

      expect(File(expectedBrickJsonPath).existsSync(), isTrue);

      final bricksPath = path.join('..', '..', '..', '..', '..', 'bricks');
      final appIconPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'app_icon'),
      );
      final docPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'documentation'),
      );
      final greetingPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'greeting'),
      );
      final simplePath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'simple'),
      );
      final todosPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'todos'),
      );
      final widgetPath = path
          .canonicalize(
            path.join(
              BricksJson.rootDir.path,
              'git',
              '''mason_60e936dbe81fab0463b4efd5a396c50e4fcf52484fe2aa189d46874215a10b52''',
              'bricks',
              'widget',
            ),
          )
          .replaceAll(r'\', '/');

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
          BrickNotFoundException(path.canonicalize('../../wrong/path')).message,
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
