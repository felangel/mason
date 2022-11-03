import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mason_api/mason_api.dart';
import 'package:mason_api/src/mason_api.dart';
import 'package:mason_api/src/models/models.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _MockHttpClient extends Mock implements http.Client {}

const token =
    '''eyJhbGciOiJSUzI1NiIsImN0eSI6IkpXVCJ9.eyJlbWFpbCI6InRlc3RAZW1haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlfQ.SaCs1BJ2Oib4TkUeR6p1uh_XnWjJnJpm-dZkL8Whsc_g-NrDKeHhkuVa8fNIbfLtdVeXjVSSi_ZjQDAJho039HSrrdhQAgrRY04cJ6IZCF1HKvJeWDcIihPdl2Zl_V5u9xBxU3ImfGpJ-0O0vCpKHIuDwZsmfN3h_CkDv3SK7lA''';
const authority = 'registry.brickhub.dev';
const credentialsFileName = 'mason-credentials.json';
const email = 'test@email.com';
const password = 'T0pS3cret!';

class TestMasonApiException extends MasonApiException {
  const TestMasonApiException({required String message, String? details})
      : super(message: message, details: details);
}

void main() {
  group('MasonApi', () {
    final tempDir = Directory.systemTemp.createTempSync();
    final environment = {'_MASON_TEST_CONFIG_DIR': tempDir.path};

    late http.Client httpClient;
    late MasonApi masonApi;

    setUp(() {
      testEnvironment = environment;
      httpClient = _MockHttpClient();
      masonApi = MasonApi(httpClient: httpClient);
    });

    test('MasonApiException overrides toString', () {
      const message = '__message';
      const details = '__details__';
      const exceptionA = TestMasonApiException(message: message);
      const exceptionB = TestMasonApiException(
        message: message,
        details: details,
      );
      expect(exceptionA.toString(), equals(message));
      expect(exceptionB.toString(), equals('$message\n$details'));
    });

    test('can be instantiated without any parameters', () {
      testEnvironment = null;
      expect(MasonApi.new, returnsNormally);
    });

    group('initialization', () {
      test('returns null user when credentials do not exist', () {
        final masonApi = MasonApi(httpClient: httpClient);
        expect(masonApi.currentUser, isNull);
      });

      test('returns null user when applicationConfigHome throws', () {
        testApplicationConfigHome = (String app) => throw Exception('oops');
        final masonApi = MasonApi(httpClient: httpClient);
        expect(masonApi.currentUser, isNull);
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
        final masonApi = MasonApi(httpClient: httpClient);
        expect(
          masonApi.currentUser,
          isA<User>()
              .having((u) => u.email, 'email', email)
              .having((u) => u.emailVerified, 'emailVerified', false),
        );
      });
    });

    group('close', () {
      test('closes the underlying httpClient', () {
        MasonApi(httpClient: httpClient).close();
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
        final masonApi = MasonApi(httpClient: httpClient);

        expect(masonApi.currentUser, isNotNull);
        expect(credentialsFile.existsSync(), isTrue);

        masonApi.logout();

        expect(masonApi.currentUser, isNull);
        expect(credentialsFile.existsSync(), isFalse);
      });
    });

    group('login', () {
      test('makes correct request (default)', () async {
        try {
          await masonApi.login(email: email, password: password);
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
        final customHostedUri = Uri.http('localhost:8080', '');
        masonApi = MasonApi(httpClient: httpClient, hostedUri: customHostedUri);
        try {
          await masonApi.login(email: email, password: password);
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

      test('throws MasonApiLoginFailure when POST throws', () async {
        final exception = Exception('oops');
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenThrow(exception);

        try {
          await masonApi.login(email: email, password: password);
          fail('should throw');
        } on MasonApiLoginFailure catch (error) {
          expect(error.message, equals('$exception'));
        }
      });

      test(
          'throws MasonApiLoginFailure '
          'when status code != 200 (unknown)', () async {
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('', HttpStatus.badRequest));

        try {
          await masonApi.login(email: email, password: password);
          fail('should throw');
        } on MasonApiLoginFailure catch (error) {
          expect(error.message, equals('An unknown error occurred.'));
        }
      });

      test(
          'throws MasonApiLoginFailure '
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
          await masonApi.login(email: email, password: password);
          fail('should throw');
        } on MasonApiLoginFailure catch (error) {
          expect(error.message, equals(message));
          expect(error.details, equals(details));
        }
      });

      test(
          'throws MasonApiLoginFailure '
          'when status code == 200 but body is malformed', () async {
        when(
          () => httpClient.post(
            Uri.https(authority, 'api/v1/oauth/token'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('{}', HttpStatus.ok));

        try {
          await masonApi.login(email: email, password: password);
          fail('should throw');
        } on MasonApiLoginFailure catch (error) {
          expect(
            error.message,
            equals(
              "type 'Null' is not a subtype of type 'String' in type cast",
            ),
          );
        }
      });

      test(
          'throws MasonApiLoginFailure '
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
          await masonApi.login(email: email, password: password);
          fail('should throw');
        } on MasonApiLoginFailure catch (error) {
          expect(error.message, equals('Exception: Invalid JWT'));
        }
      });

      test(
          'throws MasonApiLoginFailure '
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
          await masonApi.login(email: email, password: password);
          fail('should throw');
        } on MasonApiLoginFailure catch (error) {
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

        final user = await masonApi.login(email: email, password: password);
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
          await masonApi.publish(bundle: <int>[]);
          fail('should throw');
        } on MasonApiPublishFailure catch (error) {
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
        final masonApi = MasonApi(httpClient: httpClient);

        try {
          await masonApi.publish(bundle: bytes);
          fail('should throw');
        } on MasonApiPublishFailure catch (error) {
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
          masonApi = MasonApi(httpClient: httpClient);
        });

        test('makes correct refresh request', () async {
          try {
            await masonApi.publish(bundle: bytes);
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

        test('throws MasonAuthRefreshFailure when POST throws', () async {
          final exception = Exception('oops');
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/oauth/token'),
              body: any(named: 'body'),
            ),
          ).thenThrow(exception);

          try {
            await masonApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonApiPublishFailure catch (error) {
            expect(error.message, equals('Refresh failure: $exception'));
          }
        });

        test(
            'throws MasonAuthRefreshFailure '
            'when status code != 200 (unknown)', () async {
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/oauth/token'),
              body: any(named: 'body'),
            ),
          ).thenAnswer((_) async => http.Response('', HttpStatus.badRequest));

          try {
            await masonApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonApiPublishFailure catch (error) {
            expect(
              error.message,
              equals('Refresh failure: An unknown error occurred.'),
            );
          }
        });

        test(
            'throws MasonAuthRefreshFailure '
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
            await masonApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonApiPublishFailure catch (error) {
            expect(error.message, equals('Refresh failure: $message'));
          }
        });

        test(
            'throws MasonAuthRefreshFailure '
            'when status code == 200 but body is malformed', () async {
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/oauth/token'),
              body: any(named: 'body'),
            ),
          ).thenAnswer((_) async => http.Response('{}', HttpStatus.ok));

          try {
            await masonApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonApiPublishFailure catch (error) {
            expect(
              error.message,
              equals(
                """Refresh failure: type 'Null' is not a subtype of type 'String' in type cast""",
              ),
            );
          }
        });

        test(
            'throws MasonAuthRefreshFailure '
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
            await masonApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonApiPublishFailure catch (error) {
            expect(
              error.message,
              equals('Refresh failure: Exception: Invalid JWT'),
            );
          }
        });

        test(
            'throws MasonAuthRefreshFailure '
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
            await masonApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonApiPublishFailure catch (error) {
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
                'token_type': tokenType
              }),
              HttpStatus.ok,
            ),
          );

          try {
            await masonApi.publish(bundle: bytes);
          } catch (_) {}

          final user = masonApi.currentUser!;
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
          masonApi = MasonApi(httpClient: httpClient);
        });

        test('does not attempt to refresh', () async {
          try {
            await masonApi.publish(bundle: bytes);
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
            await masonApi.publish(bundle: bytes);
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

        test('throws MasonApiPublishFailure when POST throws', () async {
          final exception = Exception('oops');
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/bricks'),
              body: any(named: 'body'),
              headers: any(named: 'headers'),
            ),
          ).thenThrow(exception);

          try {
            await masonApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonApiPublishFailure catch (error) {
            expect(error.message, equals('$exception'));
          }
        });

        test(
            'throws MasonApiPublishFailure '
            'when status code != 201 (unknown)', () async {
          when(
            () => httpClient.post(
              Uri.https(authority, 'api/v1/bricks'),
              body: any(named: 'body'),
              headers: any(named: 'headers'),
            ),
          ).thenAnswer((_) async => http.Response('', HttpStatus.badRequest));

          try {
            await masonApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonApiPublishFailure catch (error) {
            expect(error.message, equals('An unknown error occurred.'));
          }
        });

        test(
            'throws MasonApiPublishFailure '
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
            await masonApi.publish(bundle: bytes);
            fail('should throw');
          } on MasonApiPublishFailure catch (error) {
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

          expect(masonApi.publish(bundle: bytes), completes);
        });
      });
    });

    group('search', () {
      const query = 'query';

      test('makes correct request', () async {
        masonApi.search(query: query).ignore();
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

        final results = await masonApi.search(query: query);
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

        final results = await masonApi.search(query: query);
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

      test('throws MasonApiSearchFailure when GET throws', () async {
        final exception = Exception('oops');

        when(
          () => httpClient.get(
            Uri.https(authority, 'api/v1/search', <String, String>{'q': query}),
          ),
        ).thenThrow(exception);

        try {
          await masonApi.search(query: 'query');
          fail('should throw');
        } on MasonApiSearchFailure catch (error) {
          expect(error.message, equals('$exception'));
        }
      });

      test(
          'throws MasonApiSearchFailure '
          'when status code != 200 (unknown)', () async {
        when(
          () => httpClient.get(
            Uri.https(authority, 'api/v1/search', <String, String>{'q': query}),
          ),
        ).thenAnswer((_) async => http.Response('', HttpStatus.badRequest));

        try {
          await masonApi.search(query: query);
          fail('should throw');
        } on MasonApiSearchFailure catch (error) {
          expect(error.message, equals('An unknown error occurred.'));
        }
      });

      test(
          'throws MasonApiSearchFailure '
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
          await masonApi.search(query: query);
          fail('should throw');
        } on MasonApiSearchFailure catch (error) {
          expect(error.message, equals(message));
          expect(error.details, equals(details));
        }
      });

      test(
          'throws MasonApiSearchFailure '
          'when status code == 200 but body is malformed', () async {
        when(
          () => httpClient.get(
            Uri.https(authority, 'api/v1/search', <String, String>{'q': query}),
          ),
        ).thenAnswer((_) async => http.Response('{}', HttpStatus.ok));

        try {
          await masonApi.search(query: query);
          fail('should throw');
        } on MasonApiSearchFailure catch (error) {
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
