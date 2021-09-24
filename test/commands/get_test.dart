import 'dart:convert';

import 'package:mason/mason.dart';
import 'package:mason/src/bricks_json.dart';
import 'package:mason/src/command.dart';
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

  group('mason get', () {
    late Logger logger;
    late MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      commandRunner = MasonCommandRunner(logger: logger);
      when(() => logger.progress(any())).thenReturn(([String? _]) {});
      setUpTestingEnvironment(cwd, suffix: '.get');

      File(path.join(Directory.current.path, 'mason.yaml'))
        ..writeAsStringSync('''bricks:
  app_icon:
    path: ../../../bricks/app_icon
  documentation:
    path: ../../../bricks/documentation
  greeting:
    path: ../../../bricks/greeting
  simple:
    path: ../../../bricks/simple
  todos:
    path: ../../../bricks/todos
  widget:
    git:
      url: https://github.com/felangel/mason
      path: bricks/widget
''');
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

      final bricksPath = path.join('..', '..', '..', 'bricks');
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
      final widgetPath =
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
            '''app_icon_cfe75d2168207dcf5ee22960c0260e93ee4168306dbeb09348c262bd7c73906e''':
                appIconPath,
            '''documentation_a4bd9a921f7902c67a8ae5918498ce13c8136233c3d11d835207447386ddd650''':
                docPath,
            '''greeting_81a4ec348561cdd721c3bb79b3d6dc14738bf17f02e18810dad2a6d88732e298''':
                greetingPath,
            '''simple_3bbc2ade88745ef690063c8f652631a4870ee6af619a327e297084251aebe232''':
                simplePath,
            '''todos_6d110323da1d9f3a3ae2ecc6feae02edef8af68ca329601f33ee29e725f1f740''':
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
      File(path.join(Directory.current.path, 'mason.yaml'))
        ..writeAsStringSync('''bricks:
  app_icon:
    path: ../../wrong/path  
''');
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
      File(path.join(Directory.current.path, 'mason.yaml'))
        ..writeAsStringSync('''bricks:
  widget:
    git:
      url: https://github.com/felangel/mason
      path: bricks/invalid
''');
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

    test('throws ProcessException when remote does not exist', () async {
      File(path.join(Directory.current.path, 'mason.yaml'))
        ..writeAsStringSync('''bricks:
  widget:
    git:
      url: https://github.com/felangel/mason1
      path: bricks/invalid
''');
      final result = await commandRunner.run(['get']);
      expect(result, equals(ExitCode.unavailable.code));
      verify(() => logger.err(any(that: contains('fatal:')))).called(1);
    });
  });
}
