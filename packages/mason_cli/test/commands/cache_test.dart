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

  group('mason cache', () {
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
      setUpTestingEnvironment(cwd, suffix: '.cache');

      File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  app_icon:
    path: ../../../../../bricks/app_icon
''',
      );
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
