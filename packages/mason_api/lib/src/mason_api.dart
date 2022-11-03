import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:http/http.dart' as http;
import 'package:mason_api/src/jwt_decode.dart';
import 'package:mason_api/src/models/models.dart';
import 'package:path/path.dart' as p;

/// {@template mason_api_exception}
/// Base for all exceptions thrown by [MasonApi].
/// {@endtemplate}
abstract class MasonApiException implements Exception {
  /// {@macro mason_api_exception}
  const MasonApiException({required this.message, this.details});

  /// The message associated with the exception.
  final String message;

  /// The details associated with the exception.
  final String? details;

  @override
  String toString() => '$message${details != null ? '\n$details' : ''}';
}

/// {@template mason_api_login_failure}
/// An exception thrown when an error occurs during `login`.
/// {@endtemplate}
class MasonApiLoginFailure extends MasonApiException {
  /// {@macro mason_api_login_failure}
  const MasonApiLoginFailure({required String message, String? details})
      : super(message: message, details: details);
}

/// {@template mason_api_refresh_failure}
/// An exception thrown when an error occurs during `refresh`.
/// {@endtemplate}
class MasonApiRefreshFailure extends MasonApiException {
  /// {@macro mason_api_refresh_failure}
  const MasonApiRefreshFailure({required String message, String? details})
      : super(message: message, details: details);
}

/// {@template mason_api_publish_failure}
/// An exception thrown when an error occurs during `publish`.
/// {@endtemplate}
class MasonApiPublishFailure extends MasonApiException {
  /// {@macro mason_api_publish_failure}
  const MasonApiPublishFailure({required String message, String? details})
      : super(message: message, details: details);
}

/// {@template mason_api_search_failure}
/// An exception thrown when an error occurs during `search`.
/// {@endtemplate}
class MasonApiSearchFailure extends MasonApiException {
  /// {@macro mason_api_search_failure}
  const MasonApiSearchFailure({required String message, String? details})
      : super(message: message, details: details);
}

/// {@template mason_api}
/// API client for the [package:mason_cli](https://github.com/felangel/mason).
/// {@endtemplate}
class MasonApi {
  /// {@macro mason_api}
  MasonApi({http.Client? httpClient, Uri? hostedUri})
      : _httpClient = httpClient ?? http.Client(),
        _hostedUri = hostedUri ?? Uri.https('registry.brickhub.dev', '') {
    _loadCredentials();
  }

  static const _applicationName = 'mason';
  static const _credentialsFileName = 'mason-credentials.json';
  static const _unknownErrorMessage = 'An unknown error occurred.';

  final Uri _hostedUri;
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

  /// Search for bricks the with the provided [query].
  Future<Iterable<BrickSearchResult>> search({required String query}) async {
    final http.Response response;
    try {
      response = await _httpClient.get(
        Uri.parse('$_hostedUri/api/v1/search?q=$query'),
      );
    } catch (error) {
      throw MasonApiSearchFailure(message: '$error');
    }

    if (response.statusCode != HttpStatus.ok) {
      final ErrorResponse error;
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        error = ErrorResponse.fromJson(body);
      } catch (_) {
        throw const MasonApiSearchFailure(message: _unknownErrorMessage);
      }
      throw MasonApiSearchFailure(
        message: error.message,
        details: error.details,
      );
    }

    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final bricksBody = (body['bricks'] as List).cast<Map<String, dynamic>>();
      return bricksBody.map<BrickSearchResult>(BrickSearchResult.fromJson);
    } catch (error) {
      throw MasonApiSearchFailure(message: '$error');
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
      throw MasonApiLoginFailure(message: '$error');
    }

    if (response.statusCode != HttpStatus.ok) {
      final ErrorResponse error;
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        error = ErrorResponse.fromJson(body);
      } catch (_) {
        throw const MasonApiLoginFailure(message: _unknownErrorMessage);
      }
      throw MasonApiLoginFailure(
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
      throw MasonApiLoginFailure(message: '$error');
    }

    _credentials = credentials;

    try {
      return _currentUser = credentials.toUser();
    } catch (error) {
      throw MasonApiLoginFailure(message: '$error');
    }
  }

  /// Log out and clear credentials.
  void logout() => _clearCredentials();

  /// Publish universal [bundle] to remote registry.
  Future<void> publish({required List<int> bundle}) async {
    var credentials = _credentials;

    if (credentials == null) {
      throw const MasonApiPublishFailure(
        message:
            '''User not found. Please make sure you are logged in and try again.''',
      );
    }

    if (credentials.areExpired) {
      try {
        credentials = await _refresh();
      } on MasonApiRefreshFailure catch (error) {
        throw MasonApiPublishFailure(
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
      throw MasonApiPublishFailure(message: '$error');
    }

    if (response.statusCode != HttpStatus.created) {
      final ErrorResponse error;
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        error = ErrorResponse.fromJson(body);
      } catch (_) {
        throw const MasonApiPublishFailure(message: _unknownErrorMessage);
      }
      throw MasonApiPublishFailure(
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
      throw MasonApiRefreshFailure(message: '$error');
    }

    if (response.statusCode != HttpStatus.ok) {
      final ErrorResponse error;
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        error = ErrorResponse.fromJson(body);
      } catch (_) {
        throw const MasonApiRefreshFailure(message: _unknownErrorMessage);
      }
      throw MasonApiRefreshFailure(
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
      throw MasonApiRefreshFailure(message: '$error');
    }

    try {
      _currentUser = credentials.toUser();
    } catch (error) {
      throw MasonApiRefreshFailure(message: '$error');
    }

    return credentials;
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
