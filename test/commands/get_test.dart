import 'dart:io';

import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/command_runner.dart';
import 'package:mason/src/mason_cache.dart';
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

      final gitUrl = 'https://github.com/felangel/mason';
      final masonUrl = path.join(MasonCache.empty().rootDir, 'git', gitUrl);

      expect(
        File(expectedBrickJsonPath).readAsStringSync(),
        equals(
          '{'
          '"${path.join(bricksPath, 'app_icon')}":"$appIconPath",'
          '"${path.join(bricksPath, 'documentation')}":"$docPath",'
          '"${path.join(bricksPath, 'greeting')}":"$greetingPath",'
          '"${path.join(bricksPath, 'todos')}":"$todosPath",'
          '"$gitUrl":"$masonUrl"'
          '}',
        ),
      );

      verify(() => logger.progress('getting bricks')).called(1);
      expect(doneCallCount, equals(1));
    });

    test('creates .mason/brick.json when mason.yaml exists with --force',
        () async {
      final expectedBrickJsonPath = path.join(
        Directory.current.path,
        '.mason',
        'bricks.json',
      );

      expect(File(expectedBrickJsonPath).existsSync(), isFalse);

      final result = await commandRunner.run(['get', '--force']);
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
        () => logger.err(
          'Could not find mason.yaml.\nDid you forget to run mason init?',
        ),
      ).called(1);
    });
  });
}
