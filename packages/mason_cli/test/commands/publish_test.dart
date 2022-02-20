import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_api/mason_api.dart';
import 'package:mason_cli/src/command_runner.dart';
import 'package:mason_cli/src/commands/commands.dart';
import 'package:mason_cli/src/version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

class MockMasonApi extends Mock implements MasonApi {}

class MockUser extends Mock implements User {}

void main() {
  final cwd = Directory.current;

  group('PublishCommand', () {
    final brickPath =
        p.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
    late Logger logger;
    late PubUpdater pubUpdater;
    late MasonApi masonApi;
    late MasonCommandRunner commandRunner;

    setUp(() async {
      logger = MockLogger();
      pubUpdater = MockPubUpdater();
      masonApi = MockMasonApi();

      when(() => logger.progress(any())).thenReturn(([String? _]) {});
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      commandRunner = MasonCommandRunner(
        logger: logger,
        masonApi: masonApi,
        pubUpdater: pubUpdater,
      );

      setUpTestingEnvironment(cwd, suffix: '.publish');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('can be instantiated without any parameters', () {
      expect(() => PublishCommand(), returnsNormally);
    });

    test('exits with code 70 when brick could not be found', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final brickYamlPath = p.join(tempDir.path, BrickYaml.file);
      Directory.current = tempDir.path;
      final result = await commandRunner.run(
        ['publish', '--directory', tempDir.path],
      );
      expect(result, equals(ExitCode.software.code));

      verify(
        () => logger.err('Could not find ${BrickYaml.file} at $brickYamlPath.'),
      ).called(1);
    });

    test('exits with code 70 when not logged in', () async {
      final result = await commandRunner.run(['publish', '-C', brickPath]);
      expect(result, equals(ExitCode.software.code));
      verify(() => logger.err('You must be logged in to publish.')).called(1);
      verify(
        () => logger.err("Run 'mason login' to log in and try again."),
      ).called(1);
    });

    test('exits with code 70 when email is not verified', () async {
      final user = MockUser();
      when(() => user.emailVerified).thenReturn(false);
      when(() => masonApi.currentUser).thenReturn(user);
      final result = await commandRunner.run(['publish', '-C', brickPath]);
      expect(result, equals(ExitCode.software.code));
      verify(
        () => logger.err('You must verify your email in order to publish.'),
      ).called(1);
    });

    test('exits with code 70 when publish fails', () async {
      final user = MockUser();
      const message = 'oops';
      when(() => user.emailVerified).thenReturn(true);
      when(() => masonApi.currentUser).thenReturn(user);
      when(
        () => masonApi.publish(bundle: any(named: 'bundle')),
      ).thenThrow(const MasonApiPublishFailure(message: message));
      final result = await commandRunner.run(['publish', '-C', brickPath]);
      expect(result, equals(ExitCode.software.code));
      verify(() => logger.progress('Publishing greeting v0.1.0+1')).called(1);
      verify(() => logger.err(message)).called(1);
      verify(() => masonApi.publish(bundle: any(named: 'bundle'))).called(1);
    });

    test('exits with code 70 when publish fails (generic)', () async {
      final user = MockUser();
      when(() => user.emailVerified).thenReturn(true);
      when(() => masonApi.currentUser).thenReturn(user);
      when(
        () => masonApi.publish(bundle: any(named: 'bundle')),
      ).thenThrow(Exception('oops'));
      final result = await commandRunner.run(['publish', '-C', brickPath]);
      expect(result, equals(ExitCode.software.code));
      verify(() => logger.progress('Publishing greeting v0.1.0+1')).called(1);
      verify(() => logger.err('Exception: oops')).called(1);
      verify(() => masonApi.publish(bundle: any(named: 'bundle'))).called(1);
    });

    test('exits with code 0 when publish succeeds', () async {
      final user = MockUser();
      final progressLogs = <String>[];
      when(() => user.emailVerified).thenReturn(true);
      when(() => masonApi.currentUser).thenReturn(user);
      when(
        () => masonApi.publish(bundle: any(named: 'bundle')),
      ).thenAnswer((_) async {});
      when(() => logger.progress(any())).thenReturn(([String? _]) {
        if (_ != null) progressLogs.add(_);
      });
      final result = await commandRunner.run(['publish', '-C', brickPath]);
      expect(result, equals(ExitCode.success.code));
      expect(progressLogs, equals(['Published greeting v0.1.0+1']));
      verify(() => logger.progress('Publishing greeting v0.1.0+1')).called(1);
      verify(() => masonApi.publish(bundle: any(named: 'bundle'))).called(1);
    });
  });
}
