import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_api/mason_api.dart';
import 'package:mason_cli/src/commands/commands.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockMasonApi extends Mock implements MasonApi {}

class _MockUser extends Mock implements User {}

class _MockArgResults extends Mock implements ArgResults {}

class _MockProgress extends Mock implements Progress {}

class FakeUri extends Fake implements Uri {}

void main() {
  final cwd = Directory.current;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(Uint8List.fromList([]));
  });

  group('PublishCommand', () {
    final brickPath =
        p.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
    late Logger logger;
    late MasonApi masonApi;
    late ArgResults argResults;
    late PublishCommand publishCommand;

    setUp(() async {
      logger = _MockLogger();
      masonApi = _MockMasonApi();
      argResults = _MockArgResults();
      publishCommand = PublishCommand(
        logger: logger,
        masonApiBuilder: ({Uri? hostedUri}) => masonApi,
      )..testArgResults = argResults;
      when(() => logger.progress(any())).thenReturn(_MockProgress());
      setUpTestingEnvironment(cwd, suffix: '.publish');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('can be instantiated without any parameters', () {
      expect(PublishCommand.new, returnsNormally);
    });

    test(
        'throws usageException when '
        'called with both --force and --dry-run', () async {
      final runner = CommandRunner<int>('mason', '')
        ..addCommand(publishCommand..testArgResults = null);
      await expectLater(
        () => runner.run(['publish', '--dry-run', '--force']),
        throwsA(
          isA<UsageException>().having(
            (e) => e.message,
            'message',
            'Cannot use both --force and --dry-run.',
          ),
        ),
      );
    });

    test('exits with code 70 when brick could not be found', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      Directory.current = tempDir.path;
      final brickYamlPath = p.join(tempDir.path, BrickYaml.file);
      when(() => argResults['directory'] as String).thenReturn(tempDir.path);
      final result = await publishCommand.run();
      expect(result, equals(ExitCode.software.code));

      verify(
        () => logger.err('Could not find ${BrickYaml.file} at $brickYamlPath.'),
      ).called(1);
      verifyNever(() => masonApi.close());
    });

    test('exits with code 70 when it is a private brick', () async {
      final brickPath = p.join('..', '..', 'bricks', 'no_registry');

      when(() => argResults['directory'] as String).thenReturn(brickPath);

      final result = await publishCommand.run();
      expect(result, equals(ExitCode.software.code));
      verify(
        () => logger.err('A private brick cannot be published.'),
      ).called(1);
      verify(
        () => logger.err('''
Please change or remove the "publish_to" field in the brick.yaml before publishing.'''),
      ).called(1);
      verifyNever(() => masonApi.close());
    });

    test('exits with code 70 when publish_to has an invalid value', () async {
      final brickPath = p.join('..', '..', 'bricks', 'invalid_registry');

      when(() => argResults['directory'] as String).thenReturn(brickPath);
      final result = await publishCommand.run();

      verify(
        () => logger.err(
          'Invalid "publish_to" in brick.yaml: "invalid registry"',
        ),
      ).called(1);
      verify(
        () => logger.err(
          '"publish_to" must be a valid registry url such as '
          '"https://registry.brickhub.dev" or "none" for private bricks.',
        ),
      ).called(1);
      verifyNever(() => masonApi.close());

      expect(result, equals(ExitCode.software.code));
    });

    test('exits with code 70 when not logged in', () async {
      when(() => argResults['directory'] as String).thenReturn(brickPath);
      final result = await publishCommand.run();
      expect(result, equals(ExitCode.software.code));
      verify(() => logger.err('You must be logged in to publish.')).called(1);
      verify(
        () => logger.err("Run 'mason login' to log in and try again."),
      ).called(1);
      verify(() => masonApi.close()).called(1);
    });

    test('exits with code 70 when email is not verified', () async {
      final user = _MockUser();
      when(() => user.emailVerified).thenReturn(false);
      when(() => masonApi.currentUser).thenReturn(user);
      when(() => argResults['directory'] as String).thenReturn(brickPath);
      final result = await publishCommand.run();
      expect(result, equals(ExitCode.software.code));
      verify(
        () => logger.err('You must verify your email in order to publish.'),
      ).called(1);
      verify(() => masonApi.close()).called(1);
    });

    test('exits with code 70 when bundle is too large', () async {
      final user = _MockUser();
      when(() => user.emailVerified).thenReturn(true);
      when(() => masonApi.currentUser).thenReturn(user);
      when(() => argResults['directory'] as String).thenReturn(brickPath);
      final publishCommand = PublishCommand(
        masonApiBuilder: ({Uri? hostedUri}) => masonApi,
        logger: logger,
        maxBundleSize: 100,
      )..testArgResults = argResults;
      final result = await publishCommand.run();
      expect(result, equals(ExitCode.software.code));
      verify(() => logger.progress('Bundling greeting')).called(1);
      verify(
        () => logger.err(
          any(
            that: contains('Hosted bricks must be smaller than 0.000095 MB.'),
          ),
        ),
      ).called(1);
      verify(() => masonApi.close()).called(1);
    });

    test('exits with code 0 without publishing when using --dry-run', () async {
      final user = _MockUser();
      final progressLogs = <String>[];
      when(() => user.emailVerified).thenReturn(true);
      when(() => masonApi.currentUser).thenReturn(user);
      when(
        () => masonApi.publish(bundle: any(named: 'bundle')),
      ).thenAnswer((_) async {});
      final progress = _MockProgress();
      when(() => progress.complete(any())).thenAnswer((invocation) {
        final update = invocation.positionalArguments[0] as String?;
        if (update != null) progressLogs.add(update);
      });
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => logger.confirm(any())).thenReturn(true);
      when(() => argResults['directory'] as String).thenReturn(brickPath);
      when(() => argResults['dry-run'] as bool).thenReturn(true);
      final result = await publishCommand.run();
      expect(result, equals(ExitCode.success.code));
      expect(progressLogs, equals(['Bundled greeting']));
      verify(() => logger.info('No issues detected.')).called(1);
      verify(
        () => logger.info('The server may enforce additional checks.'),
      ).called(1);
      verifyNever(() => logger.progress('Publishing greeting 0.1.0+1'));
      verifyNever(() {
        logger.success(
          '''\nPublished greeting 0.1.0+1 to ${BricksJson.hostedUri}.''',
        );
      });
      verifyNever(() => masonApi.publish(bundle: any(named: 'bundle')));
      verify(() => masonApi.close()).called(1);
    });

    test('exits with code 70 when publish is aborted', () async {
      final policyLink = styleUnderlined.wrap(
        link(uri: Uri.parse('https://brickhub.dev/policy')),
      );
      final user = _MockUser();
      when(() => user.emailVerified).thenReturn(true);
      when(() => masonApi.currentUser).thenReturn(user);
      when(() => logger.confirm(any())).thenReturn(false);
      when(() => argResults['directory'] as String).thenReturn(brickPath);
      final result = await publishCommand.run();
      expect(result, equals(ExitCode.software.code));
      verify(() => logger.progress('Bundling greeting')).called(1);
      verify(() {
        logger.info(
          lightCyan.wrap(
            styleBold.wrap(
              '\nPublishing is forever; bricks cannot be unpublished.',
            ),
          ),
        );
      }).called(1);
      verify(() {
        logger.info('See policy details at $policyLink\n');
      }).called(1);
      verify(
        () => logger.confirm('Do you want to publish greeting 0.1.0+1?'),
      ).called(1);
      verify(() => logger.err('Brick was not published.')).called(1);
      verifyNever(() => logger.progress('Publishing greeting 0.1.0+1'));
      verifyNever(() => masonApi.publish(bundle: any(named: 'bundle')));
      verify(() => masonApi.close()).called(1);
    });

    test('exits with code 70 when publish fails', () async {
      final user = _MockUser();
      const message = 'oops';
      const exception = MasonApiPublishFailure(message: message);
      when(() => user.emailVerified).thenReturn(true);
      when(() => masonApi.currentUser).thenReturn(user);
      when(
        () => masonApi.publish(bundle: any(named: 'bundle')),
      ).thenThrow(exception);
      when(() => logger.confirm(any())).thenReturn(true);
      when(() => argResults['directory'] as String).thenReturn(brickPath);
      final result = await publishCommand.run();
      expect(result, equals(ExitCode.software.code));
      verify(() => logger.progress('Publishing greeting 0.1.0+1')).called(1);
      verify(() => masonApi.publish(bundle: any(named: 'bundle'))).called(1);
      verify(() => masonApi.close()).called(1);
      verify(() => logger.err('$exception')).called(1);
    });

    test('exits with code 70 when publish fails (generic)', () async {
      final exception = Exception('oops');
      final user = _MockUser();
      when(() => user.emailVerified).thenReturn(true);
      when(() => masonApi.currentUser).thenReturn(user);
      when(
        () => masonApi.publish(bundle: any(named: 'bundle')),
      ).thenThrow(exception);
      when(() => logger.confirm(any())).thenReturn(true);
      when(() => argResults['directory'] as String).thenReturn(brickPath);
      await expectLater(publishCommand.run, throwsA(exception));
      verify(() => logger.progress('Publishing greeting 0.1.0+1')).called(1);
      verify(() => masonApi.publish(bundle: any(named: 'bundle'))).called(1);
      verify(() => masonApi.close()).called(1);
    });

    test('exits with code 0 when publish succeeds', () async {
      final user = _MockUser();
      final progressLogs = <String>[];
      when(() => user.emailVerified).thenReturn(true);
      when(() => masonApi.currentUser).thenReturn(user);
      when(
        () => masonApi.publish(bundle: any(named: 'bundle')),
      ).thenAnswer((_) async {});
      final progress = _MockProgress();
      when(() => progress.complete(any())).thenAnswer((invocation) {
        final update = invocation.positionalArguments[0] as String?;
        if (update != null) progressLogs.add(update);
      });
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => logger.confirm(any())).thenReturn(true);
      when(() => argResults['directory'] as String).thenReturn(brickPath);
      final result = await publishCommand.run();
      expect(result, equals(ExitCode.success.code));
      expect(
        progressLogs,
        equals(['Bundled greeting', 'Published greeting 0.1.0+1']),
      );
      verify(() => logger.progress('Publishing greeting 0.1.0+1')).called(1);
      verify(() {
        logger.success(
          '''\nPublished greeting 0.1.0+1 to ${BricksJson.hostedUri}.''',
        );
      }).called(1);
      verify(() => masonApi.publish(bundle: any(named: 'bundle'))).called(1);
      verify(() => masonApi.close()).called(1);
    });

    test('exits with code 0 when publish succeeds with --force', () async {
      final user = _MockUser();
      final progressLogs = <String>[];
      when(() => user.emailVerified).thenReturn(true);
      when(() => masonApi.currentUser).thenReturn(user);
      when(
        () => masonApi.publish(bundle: any(named: 'bundle')),
      ).thenAnswer((_) async {});
      final progress = _MockProgress();
      when(() => progress.complete(any())).thenAnswer((invocation) {
        final update = invocation.positionalArguments[0] as String?;
        if (update != null) progressLogs.add(update);
      });
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => argResults['directory'] as String).thenReturn(brickPath);
      when(() => argResults['force'] as bool).thenReturn(true);
      final result = await publishCommand.run();
      expect(result, equals(ExitCode.success.code));
      expect(
        progressLogs,
        equals(['Bundled greeting', 'Published greeting 0.1.0+1']),
      );
      verify(() => logger.progress('Publishing greeting 0.1.0+1')).called(1);
      verify(() {
        logger.success(
          '''\nPublished greeting 0.1.0+1 to ${BricksJson.hostedUri}.''',
        );
      }).called(1);
      verifyNever(() => logger.confirm(any()));
      verify(() => masonApi.publish(bundle: any(named: 'bundle'))).called(1);
      verify(() => masonApi.close()).called(1);
    });

    test(
      'exits with code 0 when publish succeeds '
      'with a custom registry (publish_to)',
      () async {
        final brickPath = p.join('..', '..', 'bricks', 'custom_registry');
        final customHostedUri = Uri.parse('https://custom.brickhub.dev');
        final user = _MockUser();
        final progressLogs = <String>[];
        when(() => user.emailVerified).thenReturn(true);

        Uri? publishTo;
        final publishCommand = PublishCommand(
          masonApiBuilder: ({Uri? hostedUri}) {
            publishTo = hostedUri;
            return masonApi;
          },
          logger: logger,
        )..testArgResults = argResults;

        when(() => masonApi.currentUser).thenReturn(user);
        when(
          () => masonApi.publish(bundle: any(named: 'bundle')),
        ).thenAnswer((_) async {});
        final progress = _MockProgress();
        when(() => progress.complete(any())).thenAnswer((invocation) {
          final update = invocation.positionalArguments[0] as String?;
          if (update != null) progressLogs.add(update);
        });
        when(() => logger.progress(any())).thenReturn(progress);
        when(() => logger.confirm(any())).thenReturn(true);
        when(() => argResults['directory'] as String).thenReturn(brickPath);
        final result = await publishCommand.run();
        expect(result, equals(ExitCode.success.code));
        expect(
          progressLogs,
          equals([
            'Bundled custom_registry',
            'Published custom_registry 0.1.0+1',
          ]),
        );

        expect(publishTo, equals(customHostedUri));

        verify(
          () => logger.progress('Publishing custom_registry 0.1.0+1'),
        ).called(1);
        verify(
          () => logger.success(
            '''\nPublished custom_registry 0.1.0+1 to $customHostedUri.''',
          ),
        ).called(1);
        verify(
          () => masonApi.publish(bundle: any(named: 'bundle')),
        ).called(1);
        verify(() => masonApi.close()).called(1);
      },
    );
  });
}
