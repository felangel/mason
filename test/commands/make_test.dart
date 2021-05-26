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

  group('mason make', () {
    late Logger logger;
    late MasonCommandRunner commandRunner;

    setUp(() {
      setUpTestingEnvironment(cwd, suffix: '.make');
      File(path.join(Directory.current.path, 'mason.yaml'))
        ..writeAsStringSync('''bricks:
  app_icon:
    path: ../../../bricks/app_icon
  documentation:
    path: ../../../bricks/documentation
  greeting:
    path: ../../../bricks/greeting
  todos:
    path: ../../../bricks/todos
  widget:
    path: ../../../bricks/widget
''');
      File(path.join(Directory.current.path, '.mason', 'bricks.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '''{"../../../bricks/app_icon":"${Directory.current.path}/../../../bricks/app_icon","../../../bricks/documentation":"${Directory.current.path}/../../../bricks/documentation","../../../bricks/greeting":"${Directory.current.path}/../../../bricks/greeting","../../../bricks/todos":"${Directory.current.path}/../../../bricks/todos","../../../bricks/widget":"${Directory.current.path}/../../../bricks/widget"}''',
        );
      logger = MockLogger();
      when(() => logger.progress(any())).thenReturn(([String? _]) {});
      commandRunner = MasonCommandRunner(logger: logger);
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('exits with code 64 when brick does not exist', () async {
      final result = await commandRunner.run(['make', 'garbage']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err(
          'Could not find a subcommand named "garbage" for "mason make".',
        ),
      ).called(1);
    });

    test('exits with code 64 when missing subcommand', () async {
      final result = await commandRunner.run(['make']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err('Missing subcommand for "mason make".'),
      ).called(1);
    });

    test('exits with code 64 when mason.yaml does not exist', () async {
      File(path.join(Directory.current.path, 'mason.yaml'))
          .deleteSync(recursive: true);
      commandRunner = MasonCommandRunner(logger: logger);
      final result = await commandRunner.run(['make', 'garbage']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err(
          'Could not find mason.yaml.\nDid you forget to run mason init?',
        ),
      ).called(1);
    });

    test('exits with code 64 when json decode fails', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'todos'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      File(path.join(testDir.path, 'todos.json'))
          .writeAsStringSync('''{"todos": [}''');
      final result = await commandRunner.run([
        'make',
        'todos',
        '--json',
        'todos.json',
      ]);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err(
          '''FormatException: Unexpected character (at character 12)
{"todos": [}
           ^
in todos.json''',
        ),
      ).called(1);
    });

    test('generates app_icon', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'app_icon'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run([
        'make',
        'app_icon',
        '--url',
        'https://cdn.dribbble.com/users/163325/screenshots/6214023/app_icon.jpg'
      ]);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'app_icon'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'app_icon'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates documentation', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'documentation'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run([
        'make',
        'documentation',
        '--name',
        'test-name',
        '--description',
        'test-description',
        '--author',
        'test-author'
      ]);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'documentation'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'documentation'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates greeting', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'greeting'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run([
        'make',
        'greeting',
        '--name',
        'test-name',
      ]);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'greeting'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'greeting'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates todos', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'todos'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      File(path.join(testDir.path, 'todos.json')).writeAsStringSync('''{
  "todos": [
    { "todo": "Eat", "done": true },
    { "todo": "Code", "done": true },
    { "todo": "Sleep", "done": false }
  ],
  "developers": [{ "name": "Alex" }, { "name": "Sam" }, { "name": "Jen" }]
}
''');
      final result = await commandRunner.run([
        'make',
        'todos',
        '--json',
        'todos.json',
      ]);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'todos'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'todos'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates widget', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'widget'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run([
        'make',
        'widget',
        '--name',
        'my_widget',
      ]);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'widget'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'widget'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });
  });
}
