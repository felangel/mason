import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mason/src/command_runner.dart';
import 'package:mason/src/mason_cache.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void setUpTestingEnvironment(Directory cwd) {
  try {
    Directory.current = path.join(
      cwd.path,
      'test',
      'fixtures',
    );
    File(
      path.join(Directory.current.path, '.mason', 'bricks.json'),
    ).deleteSync();
  } catch (_) {}
}

void main() {
  final cwd = Directory.current;

  group('mason get', () {
    Logger logger;
    MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      commandRunner = MasonCommandRunner(logger: logger);
      when(logger.progress(any)).thenReturn(([String _]) {});
      setUpTestingEnvironment(cwd);
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
      when(logger.progress(any)).thenReturn(([String _]) {
        doneCallCount++;
      });
      expect(File(expectedBrickJsonPath).existsSync(), isFalse);
      await expectLater(commandRunner.run(['get']), completes);
      expect(File(expectedBrickJsonPath).existsSync(), isTrue);
      expect(
        File(expectedBrickJsonPath).readAsStringSync(),
        equals(
          '''{"../../bricks/app_icon":"${Directory.current.path}/../../bricks/app_icon","../../bricks/documentation":"${Directory.current.path}/../../bricks/documentation","../../bricks/greeting":"${Directory.current.path}/../../bricks/greeting","../../bricks/todos":"${Directory.current.path}/../../bricks/todos","https://github.com/felangel/mason":"${MasonCache.empty().rootDir}/git/https://github.com/felangel/mason"}''',
        ),
      );
      verify(logger.progress('getting bricks')).called(1);
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
      await expectLater(commandRunner.run(['get', '--force']), completes);
      expect(File(expectedBrickJsonPath).existsSync(), isTrue);
    });

    test('does not error when brick.json already exists', () async {
      final expectedBrickJsonPath = path.join(
        Directory.current.path,
        '.mason',
        'bricks.json',
      );
      await expectLater(commandRunner.run(['get']), completes);
      await expectLater(commandRunner.run(['get']), completes);
      expect(File(expectedBrickJsonPath).existsSync(), isTrue);
    });
  });
}
