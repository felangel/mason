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

  group('mason upgrade', () {
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
      setUpTestingEnvironment(cwd, suffix: '.upgrade');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    group('local', () {
      test('updates lockfile', () async {
        File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
          '''
bricks:
  greeting: 0.1.0+1
''',
        );
        final getResult = await commandRunner.run(['get']);
        expect(getResult, equals(ExitCode.success.code));
        expect(
          File(
            path.join(Directory.current.path, MasonLockJson.file),
          ).readAsStringSync(),
          equals('{"bricks":{"greeting":"0.1.0+1"}}'),
        );
        File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
          '''
bricks:
  greeting: ^0.1.0
''',
        );

        final upgradeResult = await commandRunner.run(['upgrade']);
        expect(upgradeResult, equals(ExitCode.success.code));
        expect(
          File(
            path.join(Directory.current.path, MasonLockJson.file),
          ).readAsStringSync(),
          equals('{"bricks":{"greeting":"0.1.0+2"}}'),
        );
      });

      test('updates lockfile from nested directory', () async {
        final bricksPath = path.join('..', '..', '..', '..', '..', 'bricks');
        final simplePath = canonicalize(
          path.join(Directory.current.path, bricksPath, 'simple'),
        );
        File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
          '''
bricks:
  greeting: 0.1.0+1
  simple:
    path: ${path.join(bricksPath, 'simple')}
''',
        );
        final getResult = await commandRunner.run(['get']);
        expect(getResult, equals(ExitCode.success.code));
        expect(
          File(
            path.join(Directory.current.path, MasonLockJson.file),
          ).readAsStringSync(),
          equals(
            '{"bricks":{"greeting":"0.1.0+1","simple":{"path":"$simplePath"}}}',
          ),
        );
        File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
          '''
bricks:
  greeting: ^0.1.0
  simple:
    path: ${path.join(bricksPath, 'simple')}
''',
        );

        final nested = Directory(path.join(Directory.current.path, 'nested'))
          ..createSync();
        final workspace = Directory.current;
        Directory.current = nested.path;
        final upgradeResult = await commandRunner.run(['upgrade']);
        Directory.current = workspace;
        expect(upgradeResult, equals(ExitCode.success.code));
        expect(
          File(
            path.join(Directory.current.path, MasonLockJson.file),
          ).readAsStringSync(),
          equals(
            '{"bricks":{"greeting":"0.1.0+2","simple":{"path":"$simplePath"}}}',
          ),
        );
      });
    });

    group('global', () {
      test('updates lockfile', () async {
        await commandRunner.run(['cache', 'clear']);
        final addResult = await commandRunner.run(
          ['add', '-g', 'greeting', '0.1.0+1'],
        );
        expect(addResult, equals(ExitCode.success.code));
        expect(
          File(
            path.join(BricksJson.globalDir.path, MasonLockJson.file),
          ).readAsStringSync(),
          equals('{"bricks":{"greeting":"0.1.0+1"}}'),
        );

        final upgradeResult = await commandRunner.run(['upgrade', '-g']);
        expect(upgradeResult, equals(ExitCode.success.code));
        expect(
          File(
            path.join(BricksJson.globalDir.path, MasonLockJson.file),
          ).readAsStringSync(),
          equals('{"bricks":{"greeting":"0.1.0+2"}}'),
        );
      });
    });
  });
}
