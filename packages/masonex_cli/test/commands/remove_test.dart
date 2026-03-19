import 'dart:io';

import 'package:masonex/masonex.dart' hide packageVersion;
import 'package:masonex_cli/src/command_runner.dart';
import 'package:masonex_cli/src/version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockPubUpdater extends Mock implements PubUpdater {}

class _MockProgress extends Mock implements Progress {}

void main() {
  final cwd = Directory.current;

  group('masonex remove', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late MasonexCommandRunner commandRunner;

    setUpAll(() async {
      registerFallbackValue(Object());
      logger = _MockLogger();
      pubUpdater = _MockPubUpdater();

      when(
        () => logger.prompt(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn('');
      when(() => logger.progress(any())).thenReturn(_MockProgress());
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);
      await MasonexCommandRunner(logger: logger, pubUpdater: pubUpdater).run(
        ['cache', 'clear'],
      );
    });

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
      setUpTestingEnvironment(cwd, suffix: '.remove');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    group('local', () {
      setUp(() {
        File(p.join(Directory.current.path, 'masonex.yaml'))
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
        final progress = _MockProgress();
        when(() => progress.complete(any())).thenAnswer((invocation) {
          final update = invocation.positionalArguments[0] as String?;
          if (update?.startsWith('Removed') ?? false) {
            throw const MasonexException('oops');
          }
        });
        when(() => logger.progress(any())).thenReturn(progress);
        const url = 'https://github.com/felangel/masonex';
        final addResult = await commandRunner.run(
          [
            'add',
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

        final masonexYaml = File(p.join(Directory.current.path, 'masonex.yaml'));
        expect(masonexYaml.readAsStringSync(), contains('widget:'));

        const key = 'widget';
        final value = canonicalize(
          p.join(
            BricksJson.rootDir.path,
            'git',
            '''masonex_aHR0cHM6Ly9naXRodWIuY29tL2ZlbGFuZ2VsL21hc29u_997bc878c93534fad17d965be7cafe948a1dbb53''',
            'bricks',
            'widget',
          ),
        );
        final bricksJson = File(
          p.join(Directory.current.path, '.masonex', 'bricks.json'),
        );
        final bricksJsonContent =
            bricksJson.readAsStringSync().replaceAll(r'\\', r'\');
        expect(bricksJsonContent, contains('"$key":"$value"'));

        final removeResult = await commandRunner.run(['remove', 'widget']);
        expect(removeResult, equals(ExitCode.usage.code));
        verify(() => logger.err('oops')).called(1);
      });

      test('removes successfully when brick exists', () async {
        const url = 'https://github.com/felangel/masonex';
        final addResult = await commandRunner.run(
          [
            'add',
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

        final masonexYaml = File(p.join(Directory.current.path, 'masonex.yaml'));
        expect(masonexYaml.readAsStringSync(), contains('widget:'));

        const key = 'widget';
        final value = canonicalize(
          p.join(
            BricksJson.rootDir.path,
            'git',
            '''masonex_aHR0cHM6Ly9naXRodWIuY29tL2ZlbGFuZ2VsL21hc29u_997bc878c93534fad17d965be7cafe948a1dbb53''',
            'bricks',
            'widget',
          ),
        );
        final bricksJson = File(
          p.join(Directory.current.path, '.masonex', 'bricks.json'),
        );
        final bricksJsonContent =
            bricksJson.readAsStringSync().replaceAll(r'\\', r'\');
        expect(bricksJsonContent, contains('"$key":"$value"'));

        final removeResult = await commandRunner.run(['remove', 'widget']);
        expect(removeResult, equals(ExitCode.success.code));
        verify(() => logger.progress('Removing widget')).called(1);

        expect(masonexYaml.readAsStringSync(), isNot(contains('widget:')));
        expect(
          bricksJson.readAsStringSync(),
          isNot(contains('"$key":"$value"')),
        );
      });
    });

    group('global', () {
      setUp(() {
        try {
          File(p.join(Directory.current.path, 'masonex.yaml'))
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
        const url = 'https://github.com/felangel/masonex';
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

        final masonexYaml = File(p.join(BricksJson.globalDir.path, 'masonex.yaml'));
        expect(masonexYaml.readAsStringSync(), contains('widget:'));

        const key = 'widget';
        final value = canonicalize(
          p.join(
            BricksJson.rootDir.path,
            'git',
            '''masonex_aHR0cHM6Ly9naXRodWIuY29tL2ZlbGFuZ2VsL21hc29u_997bc878c93534fad17d965be7cafe948a1dbb53''',
            'bricks',
            'widget',
          ),
        );
        final bricksJson = File(
          p.join(BricksJson.globalDir.path, '.masonex', 'bricks.json'),
        );
        final bricksJsonContent =
            bricksJson.readAsStringSync().replaceAll(r'\\', r'\');
        expect(bricksJsonContent, contains('"$key":"$value"'));

        final removeResult =
            await commandRunner.run(['remove', '-g', 'widget']);
        expect(removeResult, equals(ExitCode.success.code));
        verify(() => logger.progress('Removing widget')).called(1);

        expect(masonexYaml.readAsStringSync(), isNot(contains('widget:')));
        expect(
          bricksJson.readAsStringSync(),
          isNot(contains('"$key":"$value"')),
        );
      });
    });
  });
}
