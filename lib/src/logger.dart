import 'package:io/ansi.dart';

/// A basic Logger which wraps [print] and applies various styles.
class Logger {
  /// Prints basic message.
  void info(String message) => print(message);

  /// Prints error message.
  void err(String message) => print(lightRed.wrap(message));

  /// Prints alert message.
  void alert(String message) => print(lightCyan.wrap(styleBold.wrap(message)));

  /// Prints success message.
  void success(String message) => print(lightGreen.wrap(message));
}
