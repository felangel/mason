import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mason_auth/mason_auth.dart';
import 'package:mason_auth/src/mason_auth.dart';
import 'package:mason_auth/src/models/credentials.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

class MockHttpClient extends Mock implements http.Client {}

const token =
    '''eyJhbGciOiJSUzI1NiIsImN0eSI6IkpXVCJ9.eyJlbWFpbCI6InRlc3RAZW1haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlfQ.SaCs1BJ2Oib4TkUeR6p1uh_XnWjJnJpm-dZkL8Whsc_g-NrDKeHhkuVa8fNIbfLtdVeXjVSSi_ZjQDAJho039HSrrdhQAgrRY04cJ6IZCF1HKvJeWDcIihPdl2Zl_V5u9xBxU3ImfGpJ-0O0vCpKHIuDwZsmfN3h_CkDv3SK7lA''';
const authority = 'registry.brickhub.dev';
const credentialsFileName = 'mason-credentials.json';
const email = 'test@email.com';
const password = 'T0pS3cret!';

void main() {
  group('MasonAuth', () {
    final tempDir = Directory.systemTemp.createTempSync();
    final environment = {'_MASON_TEST_CONFIG_DIR': tempDir.path};

    late http.Client httpClient;
    late MasonAuth masonAuth;

    setUp(() {
      testEnvironment = environment;
      httpClient = MockHttpClient();
      masonAuth = MasonAuth(httpClient: httpClient);
    });

    test('can be instantiated without any parameters', () {
      testEnvironment = null;
      expect(() => MasonAuth(), returnsNormally);
    });

    group('initialization', () {
      test('returns null user when credentials do not exist', () {
        final masonAuth = MasonAuth(httpClient: httpClient);
        expect(masonAuth.currentUser, isNull);
      });

      test('returns null user when applicationConfigHome throws', () {
        testApplicationConfigHome = (String app) => throw Exception('oops');
        final masonAuth = MasonAuth(httpClient: httpClient);
        expect(masonAuth.currentUser, isNull);
        testApplicationConfigHome = null;
      });

      test('returns user when credentials do exist', () {
        final credentials = Credentials(
          accessToken: token,
          refreshToken: '__refresh_token__',
          expiresAt: DateTime.now(),
          tokenType: 'Bearer',
        );
        File(p.join(tempDir.path, credentialsFileName)).writeAsStringSync(
          json.encode(credentials.toJson()),
        );
        final masonAuth = MasonAuth(httpClient: httpClient);
        expect(
          masonAuth.currentUser,
          isA<User>()
              .having((u) => u.email, 'email', email)
              .having((u) => u.emailVerified, 'emailVerified', false),
        );
      });
    });

    group('logout', () {
      test('clears credentials and user', () {
        final credentials = Credentials(
          accessToken: token,
          refreshToken: '__refresh_token__',
          expiresAt: DateTime.now(),
          tokenType: 'Bearer',
        );
        final credentialsFile = File(p.join(tempDir.path, credentialsFileName))
          ..writeAsStringSync(json.encode(credentials.toJson()));
        final masonAuth = MasonAuth(httpClient: httpClient);

        expect(masonAuth.currentUser, isNotNull);
        expect(credentialsFile.existsSync(), isTrue);

        masonAuth.logout();

        expect(masonAuth.currentUser, isNull);
        expect(credentialsFile.existsSync(), isFalse);
      });
    });

    group('login', () {
      test('makes correct request', () async {
        try {
          await masonAuth.login(email: email, password: password);
        } catch (_) {}
        verify(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: json.encode({
              'grant_type': 'password',
              'username': email,
              'password': password,
            }),
          ),
        ).called(1);
      });

      test('throws MasonAuthLoginFailure when POST throws', () async {
        final exception = Exception('oops');
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenThrow(exception);

        try {
          await masonAuth.login(email: email, password: password);
          fail('should throw');
        } on MasonAuthLoginFailure catch (error) {
          expect(error.message, equals('$exception'));
        }
      });

      test(
          'throws MasonAuthLoginFailure '
          'when status code != 200 (unknown)', () async {
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('', HttpStatus.badRequest));

        try {
          await masonAuth.login(email: email, password: password);
          fail('should throw');
        } on MasonAuthLoginFailure catch (error) {
          expect(error.message, equals('An unknown error occurred.'));
        }
      });

      test(
          'throws MasonAuthLoginFailure '
          'when status code != 200 (w/message)', () async {
        const message = '__message__';
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            '{"message": "$message"}',
            HttpStatus.badRequest,
          ),
        );

        try {
          await masonAuth.login(email: email, password: password);
          fail('should throw');
        } on MasonAuthLoginFailure catch (error) {
          expect(error.message, equals(message));
        }
      });

      test(
          'throws MasonAuthLoginFailure '
          'when status code == 200 but body is malformed', () async {
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('{}', HttpStatus.ok));

        try {
          await masonAuth.login(email: email, password: password);
          fail('should throw');
        } on MasonAuthLoginFailure catch (error) {
          expect(
            error.message,
            equals(
              "type 'Null' is not a subtype of type 'String' in type cast",
            ),
          );
        }
      });

      test(
          'throws MasonAuthLoginFailure '
          'when status code == 200 but jwt is invalid', () async {
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            json.encode({
              'access_token': 'malformed',
              'refresh_token': 'malformed',
              'expires_in': '3600',
              'token_type': 'Bearer'
            }),
            HttpStatus.ok,
          ),
        );

        try {
          await masonAuth.login(email: email, password: password);
          fail('should throw');
        } on MasonAuthLoginFailure catch (error) {
          expect(error.message, equals('Exception: Invalid JWT'));
        }
      });

      test(
          'throws MasonAuthLoginFailure '
          'when status code == 200 but claims are malformed', () async {
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            json.encode({
              'access_token':
                  '''eyJhbGciOiJSUzI1NiIsImN0eSI6IkpXVCJ9.eyJmb28iOiJiYXIifQ.LaR0JfOiDrS1AuABC38kzxpSjRLJ_OtfOkZ8hL6I1GPya-cJYwsmqhi5eMBwEbpYHcJhguG5l56XM6dW8xjdK7JbUN6_53gHBosSnL-Ccf29oW71Ado9sxO17YFQyihyMofJ_v78BPVy2H5O10hNjRn_M0JnnAe0Fvd2VrInlIE''',
              'refresh_token': '__refresh_token__',
              'expires_in': '3600',
              'token_type': 'Bearer'
            }),
            HttpStatus.ok,
          ),
        );

        try {
          await masonAuth.login(email: email, password: password);
          fail('should throw');
        } on MasonAuthLoginFailure catch (error) {
          expect(error.message, equals('Exception: Malformed Claims'));
        }
      });

      test('succeeds when status code == 200 and claims are valid', () async {
        const refreshToken = '__refresh_token__';
        const tokenType = 'Bearer';
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            json.encode({
              'access_token': token,
              'refresh_token': refreshToken,
              'expires_in': '42',
              'token_type': tokenType
            }),
            HttpStatus.ok,
          ),
        );

        final user = await masonAuth.login(email: email, password: password);
        expect(user.email, equals(email));
        expect(user.emailVerified, isFalse);

        final credentialsFile = File(p.join(tempDir.path, credentialsFileName));
        expect(credentialsFile.existsSync(), isTrue);
        final credentialsFileContents = credentialsFile.readAsStringSync();
        final credentials = Credentials.fromJson(
          json.decode(credentialsFileContents) as Map<String, dynamic>,
        );
        expect(credentials.accessToken, equals(token));
        expect(credentials.refreshToken, equals(refreshToken));
        expect(credentials.tokenType, equals(tokenType));
        expect(
          credentials.expiresAt.difference(DateTime.now()).inSeconds,
          closeTo(42, 1),
        );
      });
    });
  });
}
