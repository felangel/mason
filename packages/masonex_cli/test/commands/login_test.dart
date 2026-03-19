import 'package:masonex/masonex.dart';
import 'package:masonex_api/masonex_api.dart';
import 'package:masonex_cli/src/commands/commands.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockMasonexApi extends Mock implements MasonexApi {}

class _MockUser extends Mock implements User {}

class _MockProgress extends Mock implements Progress {}

void main() {
  group('LoginCommand', () {
    late Logger logger;
    late MasonexApi masonexApi;
    late LoginCommand loginCommand;

    setUp(() {
      logger = _MockLogger();
      masonexApi = _MockMasonexApi();
      loginCommand = LoginCommand(
        logger: logger,
        masonexApiBuilder: ({Uri? hostedUri}) => masonexApi,
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
      when(() => masonexApi.currentUser).thenReturn(user);

      final result = await loginCommand.run();
      expect(result, equals(ExitCode.success.code));

      verify(
        () => logger.info('You are already logged in as <${user.email}>'),
      ).called(1);
      verify(
        () => logger.info("Run 'masonex logout' to log out and try again."),
      ).called(1);
    });

    test('exits with code 70 when MasonexApiLoginFailure occurs', () async {
      const email = 'test@email.com';
      const password = 'T0pS3cret!'; // cspell:disable-line
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
      when(() => masonexApi.currentUser).thenReturn(null);
      when(
        () => masonexApi.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const MasonexApiLoginFailure(message: message));

      final result = await loginCommand.run();
      expect(result, equals(ExitCode.software.code));

      verify(() => logger.progress('Logging into brickhub.dev')).called(1);
      verify(
        () => masonexApi.login(email: email, password: password),
      ).called(1);
      verify(() => logger.err(message)).called(1);
      verify(() => masonexApi.close()).called(1);
    });

    test('exits with code 0 when logged in successfully', () async {
      const email = 'test@email.com';
      const password = 'T0pS3cret!'; // cspell:disable-line
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
      when(() => masonexApi.currentUser).thenReturn(null);
      when(
        () => masonexApi.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => user);

      final result = await loginCommand.run();
      expect(result, equals(ExitCode.success.code));

      verify(() => logger.progress('Logging into brickhub.dev')).called(1);
      verify(
        () => masonexApi.login(email: email, password: password),
      ).called(1);
      verify(
        () => logger.success('You are now logged in as <${user.email}>'),
      ).called(1);
      verify(() => masonexApi.close()).called(1);
    });
  });
}
