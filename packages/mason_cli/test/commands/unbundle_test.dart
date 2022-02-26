import 'package:mason/mason.dart' hide packageVersion;
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

  group('mason unbundle', () {
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
      setUpTestingEnvironment(cwd, suffix: '.unbundle');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('parses a brick template from a universal bundle', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'universal'),
      )..createSync(recursive: true);
      final bundlePath = path.join(
        '..',
        '..',
        '..',
        '..',
        '..',
        '..',
        'bundles/universal',
        'greeting.bundle',
      );
      Directory.current = testDir.path;
      final result = await commandRunner.run(['unbundle', bundlePath]);
      expect(result, equals(ExitCode.success.code));
      final actual = Directory(
        path.join(
          testFixturesPath(cwd, suffix: '.unbundle'),
          'universal',
        ),
      );
      final expected = Directory(
        testFixturesPath(cwd, suffix: 'unbundle'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
      verify(() => logger.progress('Unbundling greeting')).called(1);
      verify(
        () => logger.info(
          '${lightGreen.wrap('✓')} '
          'Generated 1 brick:',
        ),
      ).called(1);
      verify(
        () => logger.detail(
          '  greeting ➤ ${canonicalize(actual.path)}',
        ),
      ).called(1);
    });

    test('parses a brick template from a dart bundle', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'dart'),
      )..createSync(recursive: true);
      final bundlePath = path.join(
        '..',
        '..',
        '..',
        '..',
        '..',
        '..',
        'bundles/dart',
        'greeting_bundle.dart',
      );
      Directory.current = testDir.path;
      final result = await commandRunner.run(
        ['unbundle', bundlePath, '-t', 'dart'],
      );
      expect(result, equals(ExitCode.success.code));
      final actual = Directory(
        path.join(
          testFixturesPath(cwd, suffix: '.unbundle'),
          'dart',
        ),
      );
      final expected = Directory(
        testFixturesPath(cwd, suffix: 'unbundle'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
      verify(() => logger.progress('Unbundling greeting_bundle')).called(1);
      verify(
        () => logger.info(
          '${lightGreen.wrap('✓')} '
          'Generated 1 brick:',
        ),
      ).called(1);
      verify(
        () => logger.detail(
          '  greeting ➤ ${canonicalize(actual.path)}',
        ),
      ).called(1);
    });
  });
}
