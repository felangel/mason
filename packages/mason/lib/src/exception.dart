/// {@template mason_exception}
/// An exception thrown by an internal mason command.
/// {@endtemplate}
class MasonException implements Exception {
  /// {@macro mason_exception}
  const MasonException(this.message);

  /// The error message which will be displayed to the user via stderr.
  final String message;
}

/// {@template write_brick_exception}
/// Thrown when an error occurs while writing a brick to cache.
/// {@endtemplate}
class WriteBrickException extends MasonException {
  /// {@macro write_brick_exception}
  const WriteBrickException(String message) : super(message);
}

/// {@template brick_not_found_exception}
/// Thrown when a brick registered in the `mason.yaml` cannot be found locally.
/// {@endtemplate}
class BrickNotFoundException extends MasonException {
  /// {@macro brick_not_found_exception}
  const BrickNotFoundException(String path)
      : super('Could not find brick at $path');
}
