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

  group('masonex init', () {
    late Logger logger;
    late Progress progress;
    late PubUpdater pubUpdater;
    late MasonexCommandRunner commandRunner;

    setUp(() {
      logger = _MockLogger();
      progress = _MockProgress();
      pubUpdater = _MockPubUpdater();

      when(() => logger.progress(any())).thenReturn(progress);
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      commandRunner = MasonexCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
      setUpTestingEnvironment(cwd, suffix: '.init');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('exits with code 64 when masonex.yaml already exists', () async {
      final masonexYaml = File(path.join(Directory.current.path, 'masonex.yaml'));
      await masonexYaml.create(recursive: true);
      final result = await commandRunner.run(['init']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err('''Existing masonex.yaml at ${masonexYaml.path}'''),
      ).called(1);
    });

    test('initializes masonex when a masonex.yaml does not exist', () async {
      final result = await commandRunner.run(['init']);
      expect(result, equals(ExitCode.success.code));
      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.init')),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'init')),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
      expect(
        File(path.join(actual.path, '.masonex', 'bricks.json')).existsSync(),
        isFalse,
      );
      verify(() => logger.progress('Initializing')).called(1);
      verify(() => progress.complete('Generated 1 file.')).called(1);
    });
  });
}
