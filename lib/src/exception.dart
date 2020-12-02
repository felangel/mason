/// {@template mason_exception}
/// An exception thrown by an internal mason command.
/// {@endtemplate}
class MasonException implements Exception {
  /// {@macro mason_exception}
  const MasonException(this.message);

  /// The error message which will be displayed to the user via stderr.
  final String message;
}
