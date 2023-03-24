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
  group('LoginCommand', () {
    late Logger logger;
    late MasonApi masonApi;
    late LoginCommand loginCommand;

    setUp(() {
      logger = _MockLogger();
      masonApi = _MockMasonApi();
      loginCommand = LoginCommand(
        logger: logger,
        masonApiBuilder: ({Uri? hostedUri}) => masonApi,
      );

      when(() => logger.progress(any())).thenReturn(_MockProgress());
    });

    test('can be instantiated without any parameters', () {
      expect(LoginCommand.new, returnsNormally);
    });

    test('exits with code 0 when already logged in', () async {
      const email = 'test@email.com';
      final user = _MockUser();

      when(() => user.email).thenReturn(email);
      when(() => masonApi.currentUser).thenReturn(user);

      final result = await loginCommand.run();
      expect(result, equals(ExitCode.success.code));

      verify(
        () => logger.info('You are already logged in as <${user.email}>'),
      ).called(1);
      verify(
        () => logger.info("Run 'mason logout' to log out and try again."),
      ).called(1);
    });

    test('exits with code 70 when MasonApiLoginFailure occurs', () async {
      const email = 'test@email.com';
      const password = 'T0pS3cret!';
      const message = 'oops something went wrong!';
      when(
        () => logger.prompt('email:', defaultValue: any(named: 'defaultValue')),
      ).thenReturn(email);
      when(
        () => logger.prompt(
          'password:',
          defaultValue: any(named: 'defaultValue'),
          hidden: true,
        ),
      ).thenReturn(password);
      when(() => masonApi.currentUser).thenReturn(null);
      when(
        () => masonApi.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const MasonApiLoginFailure(message: message));

      final result = await loginCommand.run();
      expect(result, equals(ExitCode.software.code));

      verify(() => logger.progress('Logging into brickhub.dev')).called(1);
      verify(
        () => masonApi.login(email: email, password: password),
      ).called(1);
      verify(() => logger.err(message)).called(1);
      verify(() => masonApi.close()).called(1);
    });

    test('exits with code 0 when logged in successfully', () async {
      const email = 'test@email.com';
      const password = 'T0pS3cret!';
      final user = _MockUser();
      when(() => user.email).thenReturn(email);
      when(
        () => logger.prompt('email:', defaultValue: any(named: 'defaultValue')),
      ).thenReturn(email);
      when(
        () => logger.prompt(
          'password:',
          defaultValue: any(named: 'defaultValue'),
          hidden: true,
        ),
      ).thenReturn(password);
      when(() => masonApi.currentUser).thenReturn(null);
      when(
        () => masonApi.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => user);

      final result = await loginCommand.run();
      expect(result, equals(ExitCode.success.code));

      verify(() => logger.progress('Logging into brickhub.dev')).called(1);
      verify(
        () => masonApi.login(email: email, password: password),
      ).called(1);
      verify(
        () => logger.success('You are now logged in as <${user.email}>'),
      ).called(1);
      verify(() => masonApi.close()).called(1);
    });
  });
}
