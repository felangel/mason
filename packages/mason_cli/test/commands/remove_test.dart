import 'dart:io';

import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_cli/src/command_runner.dart';
import 'package:mason_cli/src/version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

class MockProgress extends Mock implements Progress {}

void main() {
  final cwd = Directory.current;

  group('mason remove', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late MasonCommandRunner commandRunner;

    setUpAll(() async {
      registerFallbackValue(Object());
      logger = MockLogger();
      pubUpdater = MockPubUpdater();

      when(
        () => logger.prompt(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn('');
      when(() => logger.progress(any())).thenReturn(MockProgress());
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);
      await MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(
        ['cache', 'clear'],
      );
    });

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
      setUpTestingEnvironment(cwd, suffix: '.remove');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    group('local', () {
      setUp(() {
        File(p.join(Directory.current.path, 'mason.yaml'))
            .writeAsStringSync('bricks:');
      });

      test('exits with code 64 when brick name is not provided', () async {
        final result = await commandRunner.run(['remove']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err('name of the brick is required.')).called(1);
      });

      test('exits with code 64 when brick does not exist', () async {
        final result = await commandRunner.run(['remove', 'garbage']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err('no brick named garbage was found')).called(1);
      });

      test('exits with code 64 when exception occurs during removal', () async {
        final progress = MockProgress();
        when(() => progress.complete(any())).thenAnswer((invocation) {
          final update = invocation.positionalArguments[0] as String?;
          if (update?.startsWith('Removed') == true) {
            throw const MasonException('oops');
          }
        });
        when(() => logger.progress(any())).thenReturn(progress);
        const url = 'https://github.com/felangel/mason';
        final addResult = await commandRunner.run(
          [
            'add',
            'widget',
            '--git-url',
            url,
            '--git-path',
            'bricks/widget',
            '--git-ref',
            '997bc878c93534fad17d965be7cafe948a1dbb53'
          ],
        );
        expect(addResult, equals(ExitCode.success.code));

        final masonYaml = File(p.join(Directory.current.path, 'mason.yaml'));
        expect(masonYaml.readAsStringSync(), contains('widget:'));

        const key = 'widget';
        final value = canonicalize(
          p.join(
            BricksJson.rootDir.path,
            'git',
            '''mason_aHR0cHM6Ly9naXRodWIuY29tL2ZlbGFuZ2VsL21hc29u_997bc878c93534fad17d965be7cafe948a1dbb53''',
            'bricks',
            'widget',
          ),
        );
        final bricksJson = File(
          p.join(Directory.current.path, '.mason', 'bricks.json'),
        );
        final bricksJsonContent =
            bricksJson.readAsStringSync().replaceAll(r'\\', r'\');
        expect(bricksJsonContent, contains('"$key":"$value"'));

        final removeResult = await commandRunner.run(['remove', 'widget']);
        expect(removeResult, equals(ExitCode.usage.code));
        verify(() => logger.err('oops')).called(1);
      });

      test('removes successfully when brick exists', () async {
        const url = 'https://github.com/felangel/mason';
        final addResult = await commandRunner.run(
          [
            'add',
            'widget',
            '--git-url',
            url,
            '--git-path',
            'bricks/widget',
            '--git-ref',
            '997bc878c93534fad17d965be7cafe948a1dbb53'
          ],
        );
        expect(addResult, equals(ExitCode.success.code));

        final masonYaml = File(p.join(Directory.current.path, 'mason.yaml'));
        expect(masonYaml.readAsStringSync(), contains('widget:'));

        const key = 'widget';
        final value = canonicalize(
          p.join(
            BricksJson.rootDir.path,
            'git',
            '''mason_aHR0cHM6Ly9naXRodWIuY29tL2ZlbGFuZ2VsL21hc29u_997bc878c93534fad17d965be7cafe948a1dbb53''',
            'bricks',
            'widget',
          ),
        );
        final bricksJson = File(
          p.join(Directory.current.path, '.mason', 'bricks.json'),
        );
        final bricksJsonContent =
            bricksJson.readAsStringSync().replaceAll(r'\\', r'\');
        expect(bricksJsonContent, contains('"$key":"$value"'));

        final removeResult = await commandRunner.run(['remove', 'widget']);
        expect(removeResult, equals(ExitCode.success.code));
        verify(() => logger.progress('Removing widget')).called(1);

        expect(masonYaml.readAsStringSync(), isNot(contains('widget:')));
        expect(
          bricksJson.readAsStringSync(),
          isNot(contains('"$key":"$value"')),
        );
      });
    });

    group('global', () {
      setUp(() {
        try {
          File(p.join(Directory.current.path, 'mason.yaml'))
              .deleteSync(recursive: true);
        } catch (_) {}
      });

      test('exits with code 64 when brick name is not provided', () async {
        final result = await commandRunner.run(['remove', '-g']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err('name of the brick is required.')).called(1);
      });

      test('exits with code 64 when brick does not exist', () async {
        final result = await commandRunner.run(['remove', '-g', 'garbage']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err('no brick named garbage was found')).called(1);
      });

      test('removes successfully when brick exists', () async {
        const url = 'https://github.com/felangel/mason';
        final addResult = await commandRunner.run(
          [
            'add',
            '-g',
            'widget',
            '--git-url',
            url,
            '--git-path',
            'bricks/widget',
            '--git-ref',
            '997bc878c93534fad17d965be7cafe948a1dbb53',
          ],
        );
        expect(addResult, equals(ExitCode.success.code));

        final masonYaml = File(p.join(BricksJson.globalDir.path, 'mason.yaml'));
        expect(masonYaml.readAsStringSync(), contains('widget:'));

        const key = 'widget';
        final value = canonicalize(
          p.join(
            BricksJson.rootDir.path,
            'git',
            '''mason_aHR0cHM6Ly9naXRodWIuY29tL2ZlbGFuZ2VsL21hc29u_997bc878c93534fad17d965be7cafe948a1dbb53''',
            'bricks',
            'widget',
          ),
        );
        final bricksJson = File(
          p.join(BricksJson.globalDir.path, '.mason', 'bricks.json'),
        );
        final bricksJsonContent =
            bricksJson.readAsStringSync().replaceAll(r'\\', r'\');
        expect(bricksJsonContent, contains('"$key":"$value"'));

        final removeResult =
            await commandRunner.run(['remove', '-g', 'widget']);
        expect(removeResult, equals(ExitCode.success.code));
        verify(() => logger.progress('Removing widget')).called(1);

        expect(masonYaml.readAsStringSync(), isNot(contains('widget:')));
        expect(
          bricksJson.readAsStringSync(),
          isNot(contains('"$key":"$value"')),
        );
      });
    });
  });
}
