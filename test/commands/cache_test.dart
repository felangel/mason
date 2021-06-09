import 'dart:io';

import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/bricks_json.dart';
import 'package:mason/src/command_runner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  final cwd = Directory.current;

  group('mason cache', () {
    late Logger logger;
    late MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      commandRunner = MasonCommandRunner(logger: logger);
      when(() => logger.progress(any())).thenReturn(([String? _]) {});
      setUpTestingEnvironment(cwd, suffix: '.cache');

      File(path.join(Directory.current.path, 'mason.yaml'))
        ..writeAsStringSync('''bricks:
  app_icon:
    path: ../../bricks/app_icon
''');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('clear removes local .mason/bricks.json', () async {
      final expectedBrickJsonPath = path.join(
        Directory.current.path,
        '.mason',
        'bricks.json',
      );

      final getResult = await commandRunner.run(['get']);
      expect(getResult, equals(ExitCode.success.code));
      expect(File(expectedBrickJsonPath).existsSync(), isTrue);

      final cacheClearResult = await commandRunner.run(['cache', 'clear']);
      expect(cacheClearResult, equals(ExitCode.success.code));
      expect(File(expectedBrickJsonPath).existsSync(), isFalse);
    });

    test('clear removes global .mason/bricks.json', () async {
      final expectedBrickJsonFile = File(
        path.join(
          BricksJson.globalDir.path,
          '.mason',
          'bricks.json',
        ),
      );

      if (!expectedBrickJsonFile.existsSync()) {
        expectedBrickJsonFile.createSync(recursive: true);
      }

      expect(expectedBrickJsonFile.existsSync(), isTrue);

      final result = await commandRunner.run(['cache', 'clear']);
      expect(result, equals(ExitCode.success.code));
      expect(expectedBrickJsonFile.existsSync(), isFalse);
    });

    test('clear removes .mason/bricks.json', () async {
      final expectedBrickJsonPath = path.join(
        Directory.current.path,
        '.mason',
        'bricks.json',
      );
      if (!BricksJson.globalDir.existsSync()) {
        BricksJson.globalDir.createSync(recursive: true);
      }

      final getResult = await commandRunner.run(['get']);
      expect(getResult, equals(ExitCode.success.code));
      expect(File(expectedBrickJsonPath).existsSync(), isTrue);
      expect(BricksJson.globalDir.existsSync(), isTrue);

      final cacheClearResult = await commandRunner.run(['cache', 'clear']);
      expect(cacheClearResult, equals(ExitCode.success.code));
      expect(File(expectedBrickJsonPath).existsSync(), isFalse);
      expect(
        File(path.join(Directory.current.path, 'mason.yaml')).existsSync(),
        isTrue,
      );
      expect(BricksJson.globalDir.existsSync(), isFalse);
    });
  });
}
