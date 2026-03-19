import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:masonex_api/masonex_api.dart';
import 'package:masonex_api/src/masonex_api.dart';
import 'package:masonex_api/src/models/models.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _MockHttpClient extends Mock implements http.Client {}

const token = // cspell:disable-next-line
    '''eyJhbGciOiJSUzI1NiIsImN0eSI6IkpXVCJ9.eyJlbWFpbCI6InRlc3RAZW1haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlfQ.SaCs1BJ2Oib4TkUeR6p1uh_XnWjJnJpm-dZkL8Whsc_g-NrDKeHhkuVa8fNIbfLtdVeXjVSSi_ZjQDAJho039HSrrdhQAgrRY04cJ6IZCF1HKvJeWDcIihPdl2Zl_V5u9xBxU3ImfGpJ-0O0vCpKHIuDwZsmfN3h_CkDv3SK7lA''';
const authority = 'registry.brickhub.dev';
const credentialsFileName = 'masonex-credentials.json';
const email = 'test@email.com';
const password = 'T0pS3cret!'; // cspell:disable-line

class TestMasonexApiException extends MasonexApiException {
  const TestMasonexApiException({required super.message, super.details});
}

void main() {
  group('MasonexApi', () {
    final tempDir = Directory.systemTemp.createTempSync();
    final environment = {'_MASON_TEST_CONFIG_DIR': tempDir.path};

    late http.Client httpClient;
    late MasonexApi masonexApi;

    setUp(() {
      testEnvironment = environment;
      httpClient = _MockHttpClient();
      masonexApi = MasonexApi(httpClient: httpClient);
    });

    test('MasonexApiException overrides toString', () {
      const message = '__message';
      const details = '__details__';
      const exceptionA = TestMasonexApiException(message: message);
      const exceptionB = TestMasonexApiException(
        message: message,
        details: details,
      );
      expect(exceptionA.toString(), equals(message));
      expect(exceptionB.toString(), equals('$message\n$details'));
    });

    test('can be instantiated without any parameters', () {
      testEnvironment = null;
      expect(MasonexApi.new, returnsNormally);
    });

    group('initialization', () {
      test('returns null user when credentials do not exist', () {
        final masonexApi = MasonexApi(httpClient: httpClient);
        expect(masonexApi.currentUser, isNull);
      });

      test('returns null user when applicationConfigHome throws', () {
        testApplicationConfigHome = (String app) => throw Exception('oops');
        final masonexApi = MasonexApi(httpClient: httpClient);
        expect(masonexApi.currentUser, isNull);
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
        final masonexApi = MasonexApi(httpClient: httpClient);
        expect(
          masonexApi.currentUser,
          isA<User>()
              .having((u) => u.email, 'email', email)
              .having((u) => u.emailVerified, 'emailVerified', false),
        );
      });
    });

    group('close', () {
      test('closes the underlying httpClient', () {
        MasonexApi(httpClient: httpClient).close();
        verify(() => httpClient.close()).called(1);
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
        final masonexApi = MasonexApi(httpClient: httpClient);

        expect(masonexApi.currentUser, isNotNull);
        expect(credentialsFile.existsSync(), isTrue);

        masonexApi.logout();

        expect(masonexApi.currentUser, isNull);
        expect(credentialsFile.existsSync(), isFalse);
      });
    });

    group('login', () {
      test('makes correct request (default)', () async {
        try {
          await masonexApi.login(email: email, password: password);
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

      test('makes correct request (custom)', () async {
        final customHostedUri = Uri.http('localhost:8080');
        masonexApi = MasonexApi(httpClient: httpClient, hostedUri: customHostedUri);
        try {
          await masonexApi.login(email: email, password: password);
        } catch (_) {}
        verify(
          () => httpClient.post(
            Uri.http(customHostedUri.authority, 'api/v1/oauth/token'),
            body: json.encode({
              'grant_type': 'password',
              'username': email,
              'password': password,
            }),
          ),
        ).called(1);
      });

      test('throws MasonexApiLoginFailure when POST throws', () async {
        final exception = Exception('oops');
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenThrow(exception);

        try {
          await masonexApi.login(email: email, password: password);
          fail('should throw');
        } on MasonexApiLoginFailure catch (error) {
          expect(error.message, equals('$exception'));
        }
      });

      test(
          'throws MasonexApiLoginFailure '
          'when status code != 200 (unknown)', () async {
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('', HttpStatus.badRequest));

        try {
          await masonexApi.login(email: email, password: password);
          fail('should throw');
        } on MasonexApiLoginFailure catch (error) {
          expect(error.message, equals('An unknown error occurred.'));
        }
      });

      test(
          'throws MasonexApiLoginFailure '
          'when status code != 200 (w/message & details)', () async {
        const code = '__code__';
        const message = '__message__';
        const details = '__details__';
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            '{"code": "$code", "message": "$message", "details": "$details"}',
            HttpStatus.badRequest,
          ),
        );

        try {
          await masonexApi.login(email: email, password: password);
          fail('should throw');
        } on MasonexApiLoginFailure catch (error) {
          expect(error.message, equals(message));
          expect(error.details, equals(details));
        }
      });

      test(
          'throws MasonexApiLoginFailure '
          'when status code == 200 but body is malformed', () async {
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('{}', HttpStatus.ok));

        try {
          await masonexApi.login(email: email, password: password);
          fail('should throw');
        } on MasonexApiLoginFailure catch (error) {
          expect(
            error.message,
            equals(
              "type 'Null' is not a subtype of type 'String' in type cast",
            ),
          );
        }
      });

      test(
          'throws MasonexApiLoginFailure '
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
              'token_type': 'Bearer',
            }),
            HttpStatus.ok,
          ),
        );

        try {
          await masonexApi.login(email: email, password: password);
          fail('should throw');
        } on MasonexApiLoginFailure catch (error) {
          expect(error.message, equals('Exception: Invalid JWT'));
        }
      });

      test(
          'throws MasonexApiLoginFailure '
          'when status code == 200 but claims are malformed', () async {
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            json.encode({
              'access_token': // cspell:disable-next-line
                  '''eyJhbGciOiJSUzI1NiIsImN0eSI6IkpXVCJ9.eyJmb28iOiJiYXIifQ.LaR0JfOiDrS1AuABC38kzxpSjRLJ_OtfOkZ8hL6I1GPya-cJYwsmqhi5eMBwEbpYHcJhguG5l56XM6dW8xjdK7JbUN6_53gHBosSnL-Ccf29oW71Ado9sxO17YFQyihyMofJ_v78BPVy2H5O10hNjRn_M0JnnAe0Fvd2VrInlIE''',
              'refresh_token': '__refresh_token__',
              'expires_in': '3600',
              'token_type': 'Bearer',
            }),
            HttpStatus.ok,
          ),
        );

        try {
          await masonexApi.login(email: email, password: password);
          fail('should throw');
        } on MasonexApiLoginFailure catch (error) {
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
              'token_type': tokenType,
            }),
            HttpStatus.ok,
          ),
        );

        final user = await masonexApi.login(email: email, password: password);
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

        try {
          await masonexApi.publish(bundle: <int>[]);
          fail('should throw');
        } on MasonexApiPublishFailure catch (error) {
          expect(
            error.message,
            isNot(
              equals(
                '''User not found. Please make sure you are logged in and try again.''',
              ),
            ),
          );
        }
      });
    });

    group('publish', () {
      final bytes = <int>[42];

      test('throws when user not found', () async {
        File(
          p.join(tempDir.path, credentialsFileName),
        ).deleteSync(recursive: true);
        final masonexApi = MasonexApi(httpClient: httpClient);

        try {
          await masonexApi.publish(bundle: bytes);
          fail('should throw');
        } on MasonexApiPublishFailure catch (error) {
          expect(
            error.message,
            equals(
              '''User not found. Please make sure you are logged in and try again.''',
            ),
          );
        }
      });

      group('with expired credentials', () {
        final credentials = Credentials(
          accessToken: token,
          refreshToken: '__refresh_token__',
          expiresAt: DateTime(2021),
          tokenType: 'Bearer',
        );

        setUp(() {
          File(p.join(tempDir.path, credentialsFileName)).writeAsStringSync(
            json.encode(credentials.toJson()),
          );
          masonexApi = MasonexApi(httpClient: httpClient);
        });

        test('makes correct refresh request', () async {
          try {
            await masonexApi.publish(bundle: bytes);
          } catch (_) {}
          verify(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/oauth/token'),
              body: json.encode({
                'grant_type': 'refresh_token',
                'refresh_token': credentials.refreshToken,
              }),
            ),
          ).called(1);
        });

        test('throws MasonexAuthRefreshFailure when POST throws', () async {
          final exception = Exception('oops');
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/oauth/token'),
              body: any(named: 'body'),
            ),
          ).thenThrow(exception);

          try {
            await masonexApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonexApiPublishFailure catch (error) {
            expect(error.message, equals('Refresh failure: $exception'));
          }
        });

        test(
            'throws MasonexAuthRefreshFailure '
            'when status code != 200 (unknown)', () async {
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/oauth/token'),
              body: any(named: 'body'),
            ),
          ).thenAnswer((_) async => http.Response('', HttpStatus.badRequest));

          try {
            await masonexApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonexApiPublishFailure catch (error) {
            expect(
              error.message,
              equals('Refresh failure: An unknown error occurred.'),
            );
          }
        });

        test(
            'throws MasonexAuthRefreshFailure '
            'when status code != 200 (w/message)', () async {
          const code = '__code__';
          const message = '__message__';
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/oauth/token'),
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async => http.Response(
              '{"code": "$code", "message": "$message"}',
              HttpStatus.badRequest,
            ),
          );

          try {
            await masonexApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonexApiPublishFailure catch (error) {
            expect(error.message, equals('Refresh failure: $message'));
          }
        });

        test(
            'throws MasonexAuthRefreshFailure '
            'when status code == 200 but body is malformed', () async {
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/oauth/token'),
              body: any(named: 'body'),
            ),
          ).thenAnswer((_) async => http.Response('{}', HttpStatus.ok));

          try {
            await masonexApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonexApiPublishFailure catch (error) {
            expect(
              error.message,
              equals(
                """Refresh failure: type 'Null' is not a subtype of type 'String' in type cast""",
              ),
            );
          }
        });

        test(
            'throws MasonexAuthRefreshFailure '
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
                'token_type': 'Bearer',
              }),
              HttpStatus.ok,
            ),
          );

          try {
            await masonexApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonexApiPublishFailure catch (error) {
            expect(
              error.message,
              equals('Refresh failure: Exception: Invalid JWT'),
            );
          }
        });

        test(
            'throws MasonexAuthRefreshFailure '
            'when status code == 200 but claims are malformed', () async {
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/oauth/token'),
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async => http.Response(
              json.encode({
                'access_token': // cspell:disable-next-line
                    '''eyJhbGciOiJSUzI1NiIsImN0eSI6IkpXVCJ9.eyJmb28iOiJiYXIifQ.LaR0JfOiDrS1AuABC38kzxpSjRLJ_OtfOkZ8hL6I1GPya-cJYwsmqhi5eMBwEbpYHcJhguG5l56XM6dW8xjdK7JbUN6_53gHBosSnL-Ccf29oW71Ado9sxO17YFQyihyMofJ_v78BPVy2H5O10hNjRn_M0JnnAe0Fvd2VrInlIE''',
                'refresh_token': '__refresh_token__',
                'expires_in': '3600',
                'token_type': 'Bearer',
              }),
              HttpStatus.ok,
            ),
          );

          try {
            await masonexApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonexApiPublishFailure catch (error) {
            expect(
              error.message,
              equals('Refresh failure: Exception: Malformed Claims'),
            );
          }
        });

        test(
            'refresh succeeds when '
            'status code == 200 and claims are valid', () async {
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
                'token_type': tokenType,
              }),
              HttpStatus.ok,
            ),
          );

          try {
            await masonexApi.publish(bundle: bytes);
          } catch (_) {}

          final user = masonexApi.currentUser!;
          expect(user.email, equals(email));
          expect(user.emailVerified, isFalse);

          final credentialsFile =
              File(p.join(tempDir.path, credentialsFileName));
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

      group('with valid credentials', () {
        final credentials = Credentials(
          accessToken: token,
          refreshToken: '__refresh_token__',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          tokenType: 'Bearer',
        );

        setUp(() {
          File(p.join(tempDir.path, credentialsFileName)).writeAsStringSync(
            json.encode(credentials.toJson()),
          );
          masonexApi = MasonexApi(httpClient: httpClient);
        });

        test('does not attempt to refresh', () async {
          try {
            await masonexApi.publish(bundle: bytes);
          } catch (_) {}

          verifyNever(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/oauth/token'),
              body: json.encode({
                'grant_type': 'refresh_token',
                'refresh_token': credentials.refreshToken,
              }),
            ),
          );
        });

        test('makes correct publish request', () async {
          try {
            await masonexApi.publish(bundle: bytes);
          } catch (_) {}

          verify(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/bricks'),
              headers: {
                'Authorization':
                    '${credentials.tokenType} ${credentials.accessToken}',
                'Content-Type': 'application/octet-stream',
              },
              body: bytes,
            ),
          ).called(1);
        });

        test('throws MasonexApiPublishFailure when POST throws', () async {
          final exception = Exception('oops');
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/bricks'),
              body: any(named: 'body'),
              headers: any(named: 'headers'),
            ),
          ).thenThrow(exception);

          try {
            await masonexApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonexApiPublishFailure catch (error) {
            expect(error.message, equals('$exception'));
          }
        });

        test(
            'throws MasonexApiPublishFailure '
            'when status code != 201 (unknown)', () async {
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/bricks'),
              body: any(named: 'body'),
              headers: any(named: 'headers'),
            ),
          ).thenAnswer((_) async => http.Response('', HttpStatus.badRequest));

          try {
            await masonexApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonexApiPublishFailure catch (error) {
            expect(error.message, equals('An unknown error occurred.'));
          }
        });

        test(
            'throws MasonexApiPublishFailure '
            'when status code != 201 (w/message & details)', () async {
          const code = '__code__';
          const message = '__message__';
          const details = '__details__';
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/bricks'),
              body: any(named: 'body'),
              headers: any(named: 'headers'),
            ),
          ).thenAnswer(
            (_) async => http.Response(
              '{"code": "$code", "message": "$message", "details": "$details"}',
              HttpStatus.badRequest,
            ),
          );

          try {
            await masonexApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonexApiPublishFailure catch (error) {
            expect(error.message, equals(message));
            expect(error.details, equals(details));
          }
        });

        test('succeeds when status code is 201', () async {
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/bricks'),
              body: any(named: 'body'),
              headers: any(named: 'headers'),
            ),
          ).thenAnswer((_) async => http.Response('{}', HttpStatus.created));

          expect(masonexApi.publish(bundle: bytes), completes);
        });
      });
    });

    group('search', () {
      const query = 'query';

      test('makes correct request', () async {
        masonexApi.search(query: query).ignore();
        verify(
          () => httpClient.get(
            Uri.https(authority, 'api/v1/search', <String, String>{'q': query}),
          ),
        ).called(1);
      });

      test('successfully decodes empty [bricks] list', () async {
        when(
          () => httpClient.get(
            Uri.https(authority, 'api/v1/search', <String, String>{'q': query}),
          ),
        ).thenAnswer(
          (_) async => http.Response('{"bricks":[],"total":0}', HttpStatus.ok),
        );

        final results = await masonexApi.search(query: query);
        expect(results, isEmpty);
      });

      test('successfully decodes populated [bricks] list', () async {
        when(
          () => httpClient.get(
            Uri.https(authority, 'api/v1/search', <String, String>{'q': query}),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            '''{"bricks":[{"name":"name","description":"description","publisher":"test@example.com","version":"0.1.0+1","created_at":"2022-04-12T22:21:32.690488Z", "downloads": 42}],"total":1}''',
            HttpStatus.ok,
          ),
        );

        final results = await masonexApi.search(query: query);
        expect(results.length, equals(1));
        expect(results.first.name, equals('name'));
        expect(results.first.description, equals('description'));
        expect(results.first.version, equals('0.1.0+1'));
        expect(
          results.first.createdAt,
          equals(DateTime.parse('2022-04-12T22:21:32.690488Z')),
        );
        expect(results.first.downloads, equals(42));
      });

      test('throws MasonexApiSearchFailure when GET throws', () async {
        final exception = Exception('oops');

        when(
          () => httpClient.get(
            Uri.https(authority, 'api/v1/search', <String, String>{'q': query}),
          ),
        ).thenThrow(exception);

        try {
          await masonexApi.search(query: 'query');
          fail('should throw');
        } on MasonexApiSearchFailure catch (error) {
          expect(error.message, equals('$exception'));
        }
      });

      test(
          'throws MasonexApiSearchFailure '
          'when status code != 200 (unknown)', () async {
        when(
          () => httpClient.get(
            Uri.https(authority, 'api/v1/search', <String, String>{'q': query}),
          ),
        ).thenAnswer((_) async => http.Response('', HttpStatus.badRequest));

        try {
          await masonexApi.search(query: query);
          fail('should throw');
        } on MasonexApiSearchFailure catch (error) {
          expect(error.message, equals('An unknown error occurred.'));
        }
      });

      test(
          'throws MasonexApiSearchFailure '
          'when status code != 200 (w/message & details)', () async {
        const code = '__code__';
        const message = '__message__';
        const details = '__details__';
        when(
          () => httpClient.get(
            Uri.https(authority, 'api/v1/search', <String, String>{'q': query}),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            '{"code": "$code", "message": "$message", "details": "$details"}',
            HttpStatus.badRequest,
          ),
        );

        try {
          await masonexApi.search(query: query);
          fail('should throw');
        } on MasonexApiSearchFailure catch (error) {
          expect(error.message, equals(message));
          expect(error.details, equals(details));
        }
      });

      test(
          'throws MasonexApiSearchFailure '
          'when status code == 200 but body is malformed', () async {
        when(
          () => httpClient.get(
            Uri.https(authority, 'api/v1/search', <String, String>{'q': query}),
          ),
        ).thenAnswer((_) async => http.Response('{}', HttpStatus.ok));

        try {
          await masonexApi.search(query: query);
          fail('should throw');
        } on MasonexApiSearchFailure catch (error) {
          expect(
            error.message,
            equals(
              "type 'Null' is not a subtype of type "
              "'List<dynamic>' in type cast",
            ),
          );
        }
      });
    });
  });
}
