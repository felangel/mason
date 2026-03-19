import 'dart:io';

import 'package:masonex/masonex.dart' hide packageVersion;
import 'package:masonex_cli/src/command_runner.dart';
import 'package:masonex_cli/src/version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockPubUpdater extends Mock implements PubUpdater {}

class _MockProgress extends Mock implements Progress {}

void main() {
  final cwd = Directory.current;

  group('masonex cache', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late MasonexCommandRunner commandRunner;

    setUp(() {
      logger = _MockLogger();
      pubUpdater = _MockPubUpdater();

      when(() => logger.progress(any())).thenReturn(_MockProgress());
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      commandRunner = MasonexCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
      setUpTestingEnvironment(cwd, suffix: '.cache');

      File(path.join(Directory.current.path, 'masonex.yaml')).writeAsStringSync(
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

    test('clear removes local .masonex/bricks.json', () async {
      final expectedBrickJsonPath = path.join(
        Directory.current.path,
        '.masonex',
        'bricks.json',
      );

      final getResult = await commandRunner.run(['get']);
      expect(getResult, equals(ExitCode.success.code));
      expect(File(expectedBrickJsonPath).existsSync(), isTrue);

      final cacheClearResult = await commandRunner.run(['cache', 'clear']);
      expect(cacheClearResult, equals(ExitCode.success.code));
      expect(File(expectedBrickJsonPath).existsSync(), isFalse);
    });

    test('clear removes global .masonex/bricks.json', () async {
      final expectedBrickJsonFile = File(
        path.join(
          BricksJson.globalDir.path,
          '.masonex',
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

    test('clear removes .masonex/bricks.json', () async {
      final expectedBrickJsonPath = path.join(
        Directory.current.path,
        '.masonex',
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
        File(path.join(Directory.current.path, 'masonex.yaml')).existsSync(),
        isTrue,
      );
      expect(BricksJson.globalDir.existsSync(), isFalse);
    });
  });
}
