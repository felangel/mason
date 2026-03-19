// coverage:ignore-file

import 'dart:io';

import 'package:masonex_logger/src/ffi/unix_terminal.dart';
import 'package:masonex_logger/src/ffi/windows_terminal.dart';

/// {@template terminal}
/// Interface for the underlying native terminal.
/// {@endtemplate}
abstract class Terminal {
  /// {@macro terminal}
  factory Terminal() => Platform.isWindows ? WindowsTerminal() : UnixTerminal();

  /// Enables raw mode which allows us to process each keypress as it comes in.
  /// https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html
  void enableRawMode();

  /// Disables raw mode and restores the terminal’s original attributes.
  void disableRawMode();
}
