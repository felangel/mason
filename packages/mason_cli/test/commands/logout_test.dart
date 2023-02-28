import 'package:mason/mason.dart';
import 'package:mason_api/mason_api.dart';
import 'package:mason_cli/src/commands/commands.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockMasonApi extends Mock implements MasonApi {}

class _MockUser extends Mock implements User {}

class _MockProgress extends Mock implements Progress {}

void main() {
  group('LogoutCommand', () {
    late Logger logger;
    late MasonApi masonApi;
    late LogoutCommand logoutCommand;

    setUp(() {
      logger = _MockLogger();
      masonApi = _MockMasonApi();
      logoutCommand = LogoutCommand(
        logger: logger,
        masonApiBuilder: ({Uri? hostedUri}) => masonApi,
      );

      when(() => logger.progress(any())).thenReturn(_MockProgress());
    });

    test('can be instantiated without any parameters', () {
      expect(LogoutCommand.new, returnsNormally);
    });

    test('exits with code 0 when already logged out', () async {
      final result = await logoutCommand.run();
      expect(result, equals(ExitCode.success.code));

      verify(
        () => logger.info('You are already logged out.'),
      ).called(1);
      verify(() => masonApi.close()).called(1);
    });

    test('exits with code 70 when exception occurs', () async {
      final user = _MockUser();
      final exception = Exception('oops');
      when(() => masonApi.currentUser).thenReturn(user);
      when(() => masonApi.logout()).thenThrow(exception);

      final result = await logoutCommand.run();
      expect(result, equals(ExitCode.software.code));

      verify(() => logger.progress('Logging out of brickhub.dev.')).called(1);
      verify(() => logger.err('$exception')).called(1);
      verify(() => masonApi.close()).called(1);
    });

    test('exits with code 0 when logged out successfully', () async {
      final user = _MockUser();
      final progressDoneCalls = <String?>[];
      when(() => masonApi.currentUser).thenReturn(user);

      final progress = _MockProgress();
      when(() => progress.complete(any())).thenAnswer((invocation) {
        final update = invocation.positionalArguments[0] as String?;
        progressDoneCalls.add(update);
      });
      when(() => logger.progress(any())).thenReturn(progress);

      final result = await logoutCommand.run();
      expect(result, equals(ExitCode.success.code));

      verify(() => logger.progress('Logging out of brickhub.dev.')).called(1);
      verify(() => masonApi.logout()).called(1);
      verify(() => masonApi.close()).called(1);
      expect(progressDoneCalls, equals(['Logged out of brickhub.dev']));
    });
  });
}
