import 'dart:io';

import 'package:args/args.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_api/mason_api.dart';
import 'package:mason_cli/src/commands/commands.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

class MockMasonApi extends Mock implements MasonApi {}

class MockUser extends Mock implements User {}

class MockArgResults extends Mock implements ArgResults {}

class MockProgress extends Mock implements Progress {}

class FakeUri extends Fake implements Uri {}

void main() {
  final cwd = Directory.current;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('PublishCommand', () {
    final brickPath =
        p.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
    late Logger logger;
    late MasonApi masonApi;
    late ArgResults argResults;
    late PublishCommand publishCommand;

    setUp(() async {
      logger = MockLogger();
      masonApi = MockMasonApi();
      argResults = MockArgResults();
      publishCommand = PublishCommand(logger: logger, masonApi: masonApi)
        ..testArgResults = argResults;
      when(() => logger.progress(any())).thenReturn(MockProgress());
      setUpTestingEnvironment(cwd, suffix: '.publish');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('can be instantiated without any parameters', () {
      expect(PublishCommand.new, returnsNormally);
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
    });

    test('exits with code 70 when it is a private brick', () async {
      final brickPath =
          p.join('..', '..', '..', '..', '..', 'bricks', 'greeting_private');

      when(() => argResults['directory'] as String).thenReturn(brickPath);

      final result = await publishCommand.run();
      expect(result, equals(ExitCode.software.code));
      verify(
        () => logger.err('A private brick cannot be published.'),
      ).called(1);
      verify(
        () => logger.err('''
Please change or remove the publish_to field in the brick.yaml before publishing'''),
      ).called(1);
    });

    test('exits with code 70 when publishTo has an invalid value', () async {
      final brickPath = p.join(
        '..',
        '..',
        '..',
        '..',
        '..',
        'bricks',
        'greeting_invalid_host',
      );

      when(() => argResults['directory'] as String).thenReturn(brickPath);
      final result = await publishCommand.run();

      verify(
        () => logger.err('Invalid host on brick.yaml: "somewhere I guess?"'),
      ).called(1);
      verify(
        () => logger.err(
          'publishTo should contain a valid registry address such as '
          '"https://registry.brickhub.dev" or "none" for private bricks.',
        ),
      ).called(1);

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
    });

    test('exits with code 70 when email is not verified', () async {
      final user = MockUser();
      when(() => user.emailVerified).thenReturn(false);
      when(() => masonApi.currentUser).thenReturn(user);
      when(() => argResults['directory'] as String).thenReturn(brickPath);
      final result = await publishCommand.run();
      expect(result, equals(ExitCode.software.code));
      verify(
        () => logger.err('You must verify your email in order to publish.'),
      ).called(1);
    });

    test('exits with code 70 when bundle is too large', () async {
      final user = MockUser();
      when(() => user.emailVerified).thenReturn(true);
      when(() => masonApi.currentUser).thenReturn(user);
      when(() => argResults['directory'] as String).thenReturn(brickPath);
      final publishCommand = PublishCommand(
        masonApi: masonApi,
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
    });

    test('exits with code 70 when publish is aborted', () async {
      final policyLink = styleUnderlined.wrap(
        link(uri: Uri.parse('https://brickhub.dev/policy')),
      );
      final user = MockUser();
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
    });

    test('exits with code 70 when publish fails', () async {
      final user = MockUser();
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
      verify(() => logger.err('$exception')).called(1);
    });

    test('exits with code 70 when publish fails (generic)', () async {
      final exception = Exception('oops');
      final user = MockUser();
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
    });

    test('exits with code 0 when publish succeeds', () async {
      final user = MockUser();
      final progressLogs = <String>[];
      when(() => user.emailVerified).thenReturn(true);
      when(() => masonApi.currentUser).thenReturn(user);
      when(
        () => masonApi.publish(bundle: any(named: 'bundle')),
      ).thenAnswer((_) async {});
      final progress = MockProgress();
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
    });

    test(
      'exits with code 0 when publish succeeds on custom host (publishTo)',
      () async {
        final brickPath = p.join(
          '..',
          '..',
          '..',
          '..',
          '..',
          'bricks',
          'greeting_custom_host',
        );

        final user = MockUser();
        final progressLogs = <String>[];
        when(() => user.emailVerified).thenReturn(true);

        final customMasonApi = MockMasonApi();

        when(() => masonApi.withCustomHostedUri(any()))
            .thenReturn(customMasonApi);

        when(() => customMasonApi.currentUser).thenReturn(user);
        when(
          () => customMasonApi.publish(bundle: any(named: 'bundle')),
        ).thenAnswer((_) async {});
        final progress = MockProgress();
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
            'Bundled greeting_custom_host',
            'Published greeting_custom_host 0.1.0+1',
          ]),
        );

        verify(
          () => masonApi
              .withCustomHostedUri(Uri.parse('https://not-brickhub.dev')),
        ).called(1);
        verify(
          () => logger.progress('Publishing greeting_custom_host 0.1.0+1'),
        ).called(1);
        verify(
          () => logger.success(
            '''\nPublished greeting_custom_host 0.1.0+1 to ${BricksJson.hostedUri}.''',
          ),
        ).called(1);
        verify(
          () => customMasonApi.publish(bundle: any(named: 'bundle')),
        ).called(1);
      },
    );
  });
}
