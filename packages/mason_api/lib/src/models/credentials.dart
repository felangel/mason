import 'package:json_annotation/json_annotation.dart';

part 'credentials.g.dart';

/// {@template credentials}
/// Credentials for an authenticated user.
/// {@endtemplate}
@JsonSerializable()
class Credentials {
  /// {@macro credentials}
  const Credentials({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.tokenType,
  });

  /// Converts a [Map] to [Credentials] from a token response.
  factory Credentials.fromTokenResponse(Map<String, dynamic> json) {
    return Credentials(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.now()
          .toUtc()
          .add(Duration(seconds: int.parse(json['expires_in'] as String))),
      tokenType: json['token_type'] as String,
    );
  }

  /// Converts a [Map] to [Credentials].
  factory Credentials.fromJson(Map<String, dynamic> json) =>
      _$CredentialsFromJson(json);

  /// The access token.
  final String accessToken;

  /// The refresh token.
  final String refreshToken;

  /// When the token expires.
  final DateTime expiresAt;

  /// The token type (usually 'Bearer').
  final String tokenType;

  /// Converts a [Credentials] to Map<String, dynamic>.
  Map<String, dynamic> toJson() => _$CredentialsToJson(this);
}
