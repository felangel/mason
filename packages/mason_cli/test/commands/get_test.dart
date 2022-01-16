import 'dart:convert';

import 'package:mason/mason.dart';
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
      const widgetPath =
          '''widget_536b4405bffd371ab46f0948d0a5b9a2ac2cddb270ebc3d6f684217f7741422f''';
      final masonUrl = path.join(
        BricksJson.rootDir.path,
        'git',
        '''mason_60e936dbe81fab0463b4efd5a396c50e4fcf52484fe2aa189d46874215a10b52''',
      );

      expect(
        File(expectedBrickJsonPath).readAsStringSync(),
        equals(
          json.encode({
            '''app_icon_0e78d754325c0a6b74c6245089fa310fd32641cf1b9e1c30ce391c07a83dfcb0''':
                appIconPath,
            '''documentation_227871e1f882f1e60fbc26adaf0d5ea0f03616b24c54ce4ffc331ebcba54018a''':
                docPath,
            '''greeting_7271b59f2b3d670acfa5ed607915573ed3e66bf38b4bb2cd8a7972bb3e17b239''':
                greetingPath,
            '''simple_6c33a2482d658c2355275550eb6960356ef483e03badf54b9e4f7daae613acd6''':
                simplePath,
            '''todos_c8800221272babb429e8e7e5cbfce6912dcb605ea323643c52b1a9ea71f4f244''':
                todosPath,
            widgetPath: masonUrl,
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
