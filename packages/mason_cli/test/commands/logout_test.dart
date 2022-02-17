import 'package:mason/mason.dart';
import 'package:mason_auth/mason_auth.dart';
import 'package:mason_cli/src/commands/commands.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockMasonAuth extends Mock implements MasonAuth {}

class MockUser extends Mock implements User {}

void main() {
  group('LogoutCommand', () {
    late Logger logger;
    late MasonAuth masonAuth;
    late LogoutCommand logoutCommand;

    setUp(() {
      logger = MockLogger();
      masonAuth = MockMasonAuth();
      logoutCommand = LogoutCommand(logger: logger, masonAuth: masonAuth);

      when(() => logger.progress(any())).thenReturn(([String? _]) {});
    });

    test('can be instantiated without any parameters', () {
      expect(() => LogoutCommand(), returnsNormally);
    });

    test('exits with code 0 when already logged out', () async {
      final result = await logoutCommand.run();
      expect(result, equals(ExitCode.success.code));

      verify(
        () => logger.info('You are already logged out.'),
      ).called(1);
    });

    test('exits with code 70 when exception occurs', () async {
      final user = MockUser();
      final exception = Exception('oops');
      when(() => masonAuth.currentUser).thenReturn(user);
      when(() => masonAuth.logout()).thenThrow(exception);

      final result = await logoutCommand.run();
      expect(result, equals(ExitCode.software.code));

      verify(() => logger.progress('Logging out of brickhub.dev.')).called(1);
      verify(() => logger.err('$exception')).called(1);
    });

    test('exits with code 0 when logged out successfully', () async {
      final user = MockUser();
      final progressDoneCalls = <String?>[];
      when(() => masonAuth.currentUser).thenReturn(user);

      // ignore: unnecessary_lambdas
      when(() => logger.progress(any())).thenReturn(([String? _]) {
        progressDoneCalls.add(_);
      });

      final result = await logoutCommand.run();
      expect(result, equals(ExitCode.success.code));

      verify(() => logger.progress('Logging out of brickhub.dev.')).called(1);
      verify(() => masonAuth.logout()).called(1);
      expect(progressDoneCalls, equals(['Logged out of brickhub.dev']));
    });
  });
}
