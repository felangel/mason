// coverage:ignore-file
// ignore_for_file: public_member_api_docs

import 'package:mason_logger/src/ffi/terminal.dart';
import 'package:win32/win32.dart';

class WindowsTerminal implements Terminal {
  WindowsTerminal() : inputHandle = GetStdHandle(STD_INPUT_HANDLE).value;

  final HANDLE inputHandle;

  @override
  void enableRawMode() {
    final dwMode =
        const CONSOLE_MODE(-1) &
        (~ENABLE_ECHO_INPUT) &
        (~ENABLE_PROCESSED_INPUT) &
        (~ENABLE_LINE_INPUT) &
        (~ENABLE_WINDOW_INPUT);
    SetConsoleMode(inputHandle, dwMode);
  }

  @override
  void disableRawMode() {
    final dwMode =
        ENABLE_ECHO_INPUT |
        ENABLE_EXTENDED_FLAGS |
        ENABLE_INSERT_MODE |
        ENABLE_LINE_INPUT |
        ENABLE_MOUSE_INPUT |
        ENABLE_PROCESSED_INPUT |
        ENABLE_QUICK_EDIT_MODE |
        ENABLE_VIRTUAL_TERMINAL_INPUT;
    SetConsoleMode(inputHandle, dwMode);
  }
}
