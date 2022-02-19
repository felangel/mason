import 'dart:convert';

import 'package:cli_util/cli_util.dart';
import 'package:http/http.dart' as http;
import 'package:mason_auth/src/jwt_decode.dart';
import 'package:mason_auth/src/models/models.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

/// {@template mason_auth_exception}
/// Base for all exceptions thrown by [MasonAuth].
/// {@endtemplate}
abstract class MasonAuthException implements Exception {
  /// {@macro mason_auth_exception}
  const MasonAuthException({required this.message});

  /// The message associated with the exception.
  final String message;
}

/// {@template mason_auth_login_failure}
/// An exception thrown when an error occurs during `login`.
/// {@endtemplate}
class MasonAuthLoginFailure extends MasonAuthException {
  /// {@macro mason_auth_login_failure}
  const MasonAuthLoginFailure({required String message})
      : super(message: message);
}

/// {@template mason_auth_refresh_failure}
/// An exception thrown when an error occurs during `refresh`.
/// {@endtemplate}
class MasonAuthRefreshFailure extends MasonAuthException {
  /// {@macro mason_auth_refresh_failure}
  const MasonAuthRefreshFailure({required String message})
      : super(message: message);
}

/// {@template mason_auth_publish_failure}
/// An exception thrown when an error occurs during `publish`.
/// {@endtemplate}
class MasonAuthPublishFailure extends MasonAuthException {
  /// {@macro mason_auth_publish_failure}
  const MasonAuthPublishFailure({required String message})
      : super(message: message);
}

/// {@template mason_auth}
/// Authentication client for the [Mason CLI](https://github.com/felangel/mason).
/// {@endtemplate}
class MasonAuth {
  /// {@macro mason_auth}
  MasonAuth({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client() {
    _loadCredentials();
  }

  static const _authority = 'registry.brickhub.dev';
  static const _applicationName = 'mason';
  static const _credentialsFileName = 'mason-credentials.json';

  final http.Client _httpClient;

  /// The location for mason-specific configuration.
  ///
  /// `null` if no config dir could be found.
  final String? _masonConfigDir = () {
    final environment = testEnvironment ?? Platform.environment;
    if (environment.containsKey('_MASON_TEST_CONFIG_DIR')) {
      return environment['_MASON_TEST_CONFIG_DIR'];
    }
    try {
      final configHome = testApplicationConfigHome ?? applicationConfigHome;
      return configHome(_applicationName);
    } catch (_) {
      return null;
    }
  }();

  Credentials? _credentials;

  User? _currentUser;

  /// The current user.
  User? get currentUser => _currentUser;

  /// Log in with the provided [email] and [password].
  Future<User> login({required String email, required String password}) async {
    late final http.Response response;
    try {
      response = await _httpClient.post(
        Uri.https(_authority, 'api/v1/oauth/token'),
        body: json.encode({
          'grant_type': 'password',
          'username': email,
          'password': password,
        }),
      );
    } catch (error) {
      throw MasonAuthLoginFailure(message: '$error');
    }

    if (response.statusCode != HttpStatus.ok) {
      var message = 'An unknown error occurred.';
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        message = body['message'] as String;
      } catch (_) {}
      throw MasonAuthLoginFailure(message: message);
    }

    late final Credentials credentials;
    try {
      credentials = Credentials.fromTokenResponse(
        json.decode(response.body) as Map<String, dynamic>,
      );
      _flushCredentials(credentials);
    } catch (error) {
      throw MasonAuthLoginFailure(message: '$error');
    }

    try {
      return _currentUser = credentials.toUser();
    } catch (error) {
      throw MasonAuthLoginFailure(message: '$error');
    }
  }

  /// Log out and clear credentials.
  void logout() => _clearCredentials();

  /// Publish universal [bundle] to remote registry.
  Future<void> publish({required List<int> bundle}) async {
    final credentials = _credentials;

    if (credentials == null) {
      throw const MasonAuthPublishFailure(
        message:
            '''User not found. Please make sure you are logged in and try again.''',
      );
    }

    if (credentials.areExpired) {
      try {
        await _refresh();
      } on MasonAuthRefreshFailure catch (error) {
        throw MasonAuthPublishFailure(
          message: 'Refresh failure: ${error.message}',
        );
      }
    }

    final uri = Uri.https(_authority, 'api/v1/bricks');
    final headers = {
      'Authorization': '${credentials.tokenType} ${credentials.accessToken}',
      'Content-Type': 'application/octet-stream',
    };

    late final http.Response response;
    try {
      response = await _httpClient.post(
        uri,
        headers: headers,
        body: bundle,
      );
    } catch (error) {
      throw MasonAuthPublishFailure(message: '$error');
    }

    if (response.statusCode != HttpStatus.created) {
      var message = 'An unknown error occurred.';
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        message = body['message'] as String;
      } catch (_) {}
      throw MasonAuthPublishFailure(message: message);
    }
  }

  /// Attempt to refresh the current credentials and return
  /// a new [User] with refreshed credentials.
  Future<User> _refresh() async {
    late final http.Response response;
    try {
      response = await _httpClient.post(
        Uri.https(_authority, 'api/v1/oauth/token'),
        body: json.encode({
          'grant_type': 'refresh_token',
          'refresh_token': _credentials!.refreshToken,
        }),
      );
    } catch (error) {
      throw MasonAuthRefreshFailure(message: '$error');
    }

    if (response.statusCode != HttpStatus.ok) {
      var message = 'An unknown error occurred.';
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        message = body['message'] as String;
      } catch (_) {}
      throw MasonAuthRefreshFailure(message: message);
    }

    late final Credentials credentials;
    try {
      credentials = Credentials.fromTokenResponse(
        json.decode(response.body) as Map<String, dynamic>,
      );
      _flushCredentials(credentials);
    } catch (error) {
      throw MasonAuthRefreshFailure(message: '$error');
    }

    try {
      return _currentUser = credentials.toUser();
    } catch (error) {
      throw MasonAuthRefreshFailure(message: '$error');
    }
  }

  void _loadCredentials() {
    final masonConfigDir = _masonConfigDir;
    if (masonConfigDir == null) return;

    final credentialsFile = File(p.join(masonConfigDir, _credentialsFileName));

    if (credentialsFile.existsSync()) {
      try {
        final contents = credentialsFile.readAsStringSync();
        _credentials = Credentials.fromJson(
          json.decode(contents) as Map<String, dynamic>,
        );
        _currentUser = _credentials?.toUser();
      } catch (_) {}
    }
  }

  void _flushCredentials(Credentials credentials) {
    final masonConfigDir = _masonConfigDir;
    if (masonConfigDir == null) return;

    final credentialsFile = File(p.join(masonConfigDir, _credentialsFileName));

    if (!credentialsFile.existsSync()) {
      credentialsFile.createSync(recursive: true);
    }

    credentialsFile.writeAsStringSync(json.encode(credentials.toJson()));
  }

  void _clearCredentials() {
    _credentials = null;
    _currentUser = null;

    final masonConfigDir = _masonConfigDir;
    if (masonConfigDir == null) return;

    final credentialsFile = File(p.join(masonConfigDir, _credentialsFileName));
    if (credentialsFile.existsSync()) {
      credentialsFile.deleteSync(recursive: true);
    }
  }
}

extension on Credentials {
  User toUser() {
    final jwt = accessToken;
    final claims = Jwt.decodeClaims(jwt);

    if (claims == null) throw Exception('Invalid JWT');

    try {
      return User(
        email: claims['email'] as String,
        emailVerified: claims['email_verified'] as bool,
      );
    } catch (_) {
      throw Exception('Malformed Claims');
    }
  }

  /// Whether the credentials have expired.
  bool get areExpired {
    return DateTime.now().add(const Duration(minutes: 1)).isAfter(expiresAt);
  }
}

/// Test environment which should only be used for testing purposes.
Map<String, String>? testEnvironment;

/// Test applicationConfigHome which should only be used for testing purposes.
String Function(String)? testApplicationConfigHome;
