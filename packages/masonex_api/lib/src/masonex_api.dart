import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:http/http.dart' as http;
import 'package:masonex_api/src/jwt_decode.dart';
import 'package:masonex_api/src/models/models.dart';
import 'package:path/path.dart' as p;

/// {@template masonex_api_exception}
/// Base for all exceptions thrown by [MasonexApi].
/// {@endtemplate}
abstract class MasonexApiException implements Exception {
  /// {@macro masonex_api_exception}
  const MasonexApiException({required this.message, this.details});

  /// The message associated with the exception.
  final String message;

  /// The details associated with the exception.
  final String? details;

  @override
  String toString() => '$message${details != null ? '\n$details' : ''}';
}

/// {@template masonex_api_login_failure}
/// An exception thrown when an error occurs during `login`.
/// {@endtemplate}
class MasonexApiLoginFailure extends MasonexApiException {
  /// {@macro masonex_api_login_failure}
  const MasonexApiLoginFailure({required super.message, super.details});
}

/// {@template masonex_api_refresh_failure}
/// An exception thrown when an error occurs during `refresh`.
/// {@endtemplate}
class MasonexApiRefreshFailure extends MasonexApiException {
  /// {@macro masonex_api_refresh_failure}
  const MasonexApiRefreshFailure({required super.message, super.details});
}

/// {@template masonex_api_publish_failure}
/// An exception thrown when an error occurs during `publish`.
/// {@endtemplate}
class MasonexApiPublishFailure extends MasonexApiException {
  /// {@macro masonex_api_publish_failure}
  const MasonexApiPublishFailure({required super.message, super.details});
}

/// {@template masonex_api_search_failure}
/// An exception thrown when an error occurs during `search`.
/// {@endtemplate}
class MasonexApiSearchFailure extends MasonexApiException {
  /// {@macro masonex_api_search_failure}
  const MasonexApiSearchFailure({required super.message, super.details});
}

/// {@template masonex_api}
/// API client for the [package:masonex_cli](https://github.com/felangel/masonex).
/// {@endtemplate}
class MasonexApi {
  /// {@macro masonex_api}
  MasonexApi({http.Client? httpClient, Uri? hostedUri})
      : _httpClient = httpClient ?? http.Client(),
        _hostedUri = hostedUri ?? Uri.https('registry.brickhub.dev') {
    _loadCredentials();
  }

  static const _applicationName = 'masonex';
  static const _credentialsFileName = 'masonex-credentials.json';
  static const _unknownErrorMessage = 'An unknown error occurred.';

  final Uri _hostedUri;
  final http.Client _httpClient;

  /// The location for masonex-specific configuration.
  ///
  /// `null` if no config dir could be found.
  final String? _masonexConfigDir = () {
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

  /// Search for bricks the with the provided [query].
  Future<Iterable<BrickSearchResult>> search({required String query}) async {
    final http.Response response;
    try {
      response = await _httpClient.get(
        Uri.parse('$_hostedUri/api/v1/search?q=$query'),
      );
    } catch (error) {
      throw MasonexApiSearchFailure(message: '$error');
    }

    if (response.statusCode != HttpStatus.ok) {
      final ErrorResponse error;
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        error = ErrorResponse.fromJson(body);
      } catch (_) {
        throw const MasonexApiSearchFailure(message: _unknownErrorMessage);
      }
      throw MasonexApiSearchFailure(
        message: error.message,
        details: error.details,
      );
    }

    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final bricksBody = (body['bricks'] as List).cast<Map<String, dynamic>>();
      return bricksBody.map<BrickSearchResult>(BrickSearchResult.fromJson);
    } catch (error) {
      throw MasonexApiSearchFailure(message: '$error');
    }
  }

  /// Log in with the provided [email] and [password].
  Future<User> login({required String email, required String password}) async {
    final http.Response response;
    try {
      response = await _httpClient.post(
        Uri.parse('$_hostedUri/api/v1/oauth/token'),
        body: json.encode({
          'grant_type': 'password',
          'username': email,
          'password': password,
        }),
      );
    } catch (error) {
      throw MasonexApiLoginFailure(message: '$error');
    }

    if (response.statusCode != HttpStatus.ok) {
      final ErrorResponse error;
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        error = ErrorResponse.fromJson(body);
      } catch (_) {
        throw const MasonexApiLoginFailure(message: _unknownErrorMessage);
      }
      throw MasonexApiLoginFailure(
        message: error.message,
        details: error.details,
      );
    }

    final Credentials credentials;
    try {
      credentials = Credentials.fromTokenResponse(
        json.decode(response.body) as Map<String, dynamic>,
      );
      _flushCredentials(credentials);
    } catch (error) {
      throw MasonexApiLoginFailure(message: '$error');
    }

    _credentials = credentials;

    try {
      return _currentUser = credentials.toUser();
    } catch (error) {
      throw MasonexApiLoginFailure(message: '$error');
    }
  }

  /// Log out and clear credentials.
  void logout() => _clearCredentials();

  /// Publish universal [bundle] to remote registry.
  Future<void> publish({required List<int> bundle}) async {
    var credentials = _credentials;

    if (credentials == null) {
      throw const MasonexApiPublishFailure(
        message:
            '''User not found. Please make sure you are logged in and try again.''',
      );
    }

    if (credentials.areExpired) {
      try {
        credentials = await _refresh();
      } on MasonexApiRefreshFailure catch (error) {
        throw MasonexApiPublishFailure(
          message: 'Refresh failure: ${error.message}',
        );
      }
    }

    final http.Response response;
    try {
      response = await _httpClient.post(
        Uri.parse('$_hostedUri/api/v1/bricks'),
        headers: {
          'Authorization':
              '${credentials.tokenType} ${credentials.accessToken}',
          'Content-Type': 'application/octet-stream',
        },
        body: bundle,
      );
    } catch (error) {
      throw MasonexApiPublishFailure(message: '$error');
    }

    if (response.statusCode != HttpStatus.created) {
      final ErrorResponse error;
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        error = ErrorResponse.fromJson(body);
      } catch (_) {
        throw const MasonexApiPublishFailure(message: _unknownErrorMessage);
      }
      throw MasonexApiPublishFailure(
        message: error.message,
        details: error.details,
      );
    }
  }

  /// Closes the client and cleans up any resources associated with it.
  /// It's important to close each client when it's done being used;
  /// failing to do so can cause the Dart process to hang.
  void close() => _httpClient.close();

  /// Attempt to refresh the current credentials and return
  /// refreshed credentials.
  Future<Credentials> _refresh() async {
    final http.Response response;
    try {
      response = await _httpClient.post(
        Uri.parse('$_hostedUri/api/v1/oauth/token'),
        body: json.encode({
          'grant_type': 'refresh_token',
          'refresh_token': _credentials!.refreshToken,
        }),
      );
    } catch (error) {
      throw MasonexApiRefreshFailure(message: '$error');
    }

    if (response.statusCode != HttpStatus.ok) {
      final ErrorResponse error;
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        error = ErrorResponse.fromJson(body);
      } catch (_) {
        throw const MasonexApiRefreshFailure(message: _unknownErrorMessage);
      }
      throw MasonexApiRefreshFailure(
        message: error.message,
        details: error.details,
      );
    }

    final Credentials credentials;
    try {
      credentials = Credentials.fromTokenResponse(
        json.decode(response.body) as Map<String, dynamic>,
      );
      _flushCredentials(credentials);
    } catch (error) {
      throw MasonexApiRefreshFailure(message: '$error');
    }

    try {
      _currentUser = credentials.toUser();
    } catch (error) {
      throw MasonexApiRefreshFailure(message: '$error');
    }

    return credentials;
  }

  void _loadCredentials() {
    final masonexConfigDir = _masonexConfigDir;
    if (masonexConfigDir == null) return;

    final credentialsFile = File(p.join(masonexConfigDir, _credentialsFileName));

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
    final masonexConfigDir = _masonexConfigDir;
    if (masonexConfigDir == null) return;

    final credentialsFile = File(p.join(masonexConfigDir, _credentialsFileName));

    if (!credentialsFile.existsSync()) {
      credentialsFile.createSync(recursive: true);
    }

    credentialsFile.writeAsStringSync(json.encode(credentials.toJson()));
  }

  void _clearCredentials() {
    _credentials = null;
    _currentUser = null;

    final masonexConfigDir = _masonexConfigDir;
    if (masonexConfigDir == null) return;

    final credentialsFile = File(p.join(masonexConfigDir, _credentialsFileName));
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
