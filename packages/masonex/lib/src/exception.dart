/// {@template masonex_exception}
/// An exception thrown by an internal masonex command.
/// {@endtemplate}
class MasonexException implements Exception {
  /// {@macro masonex_exception}
  const MasonexException(this.message);

  /// The error message which will be displayed to the user via stderr.
  final String message;

  @override
  String toString() => message;
}

/// {@template brick_not_found_exception}
/// Thrown when a brick registered in the `masonex.yaml` cannot be found locally.
/// {@endtemplate}
class BrickNotFoundException extends MasonexException {
  /// {@macro brick_not_found_exception}
  const BrickNotFoundException(String path)
      : super('Could not find brick at $path');
}
