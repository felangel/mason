/// Indicates the desired logging level.
enum LogLevel {
  /// Logs everything, no matter what levels will be added in the future.
  ///
  /// This is the default level.
  all,

  /// Log detail, success, info, warning, error, and alert messages.
  detail,

  /// Log success, info, warning, error, and alert messages.
  info,

  /// Log success, info, warning, error, and alert messages.
  success,

  /// Log warning, error and alert messages.
  warn,

  /// Log error and alert messages.
  error,

  /// Only log alert messages
  alert,

  /// Logs nothing.
  none,
}
