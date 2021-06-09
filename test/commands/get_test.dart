import 'dart:convert';
import 'dart:io';

import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/command.dart';
import 'package:mason/src/command_runner.dart';
import 'package:mason/src/bricks_json.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

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
    path: ../../bricks/app_icon
  documentation:
    path: ../../bricks/documentation
  greeting:
    path: ../../bricks/greeting
  todos:
    path: ../../bricks/todos
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

      final bricksPath = path.join('..', '..', 'bricks');
      final appIconPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'app_icon'),
      );
      final docPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'documentation'),
      );
      final greetingPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'greeting'),
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
            '''app_icon_7fe065ff20ef089c36df9d567df1bd7d328c6bb017fdbff4733cdd3783a0e591''':
                appIconPath,
            '''documentation_df43721ae5bfb5f7b07117d7fdf4eb70de9048652b8dfed2ea7492d34010664a''':
                docPath,
            '''greeting_a4652001e26be10014b29359c36b1e52c04faf4ef12c0d9560e73d2f0c2641f8''':
                greetingPath,
            '''todos_73b2e1ae179e296b318703953a86f28a792e94bed4a9adec9f8ee5893c4527a7''':
                todosPath,
            widgetPath: masonUrl,
          }),
        ),
      );

      verify(() => logger.progress('getting bricks')).called(1);
      expect(doneCallCount, equals(1));
    });

    test('creates .mason/brick.json when mason.yaml exists', () async {
      final expectedBrickJsonPath = path.join(
        Directory.current.path,
        '.mason',
        'bricks.json',
      );

      expect(File(expectedBrickJsonPath).existsSync(), isFalse);

      final result = await commandRunner.run(['get']);
      expect(result, equals(ExitCode.success.code));

      expect(File(expectedBrickJsonPath).existsSync(), isTrue);
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
  });
}
