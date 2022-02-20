/// {@template user}
/// A mason user account.
/// {@endtemplate}
class User {
  /// {@macro user}
  const User({
    required this.email,
    required this.emailVerified,
  });

  /// The user's email address.
  final String email;

  /// Whether the user's email address has been verified.
  final bool emailVerified;
}
