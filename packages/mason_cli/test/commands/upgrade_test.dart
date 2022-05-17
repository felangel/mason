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

  group('mason upgrade', () {
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
      setUpTestingEnvironment(cwd, suffix: '.upgrade');
    });

    tearDown(() {
      Directory.current = cwd;
    });

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
  });
}
