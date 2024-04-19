// coverage:ignore-file
// ignore_for_file: public_member_api_docs

import 'package:mason_logger/src/ffi/terminal.dart';
import 'package:win32/win32.dart';

class WindowsTerminal implements Terminal {
  WindowsTerminal() {
    outputHandle = GetStdHandle(STD_HANDLE.STD_OUTPUT_HANDLE);
    inputHandle = GetStdHandle(STD_HANDLE.STD_INPUT_HANDLE);
  }

  late final int inputHandle;
  late final int outputHandle;

  @override
  void enableRawMode() {
    const dwMode = (~CONSOLE_MODE.ENABLE_ECHO_INPUT) &
        (~CONSOLE_MODE.ENABLE_PROCESSED_INPUT) &
        (~CONSOLE_MODE.ENABLE_LINE_INPUT) &
        (~CONSOLE_MODE.ENABLE_WINDOW_INPUT);
    SetConsoleMode(inputHandle, dwMode);
  }

  @override
  void disableRawMode() {
    const dwMode = CONSOLE_MODE.ENABLE_ECHO_INPUT |
        CONSOLE_MODE.ENABLE_EXTENDED_FLAGS |
        CONSOLE_MODE.ENABLE_INSERT_MODE |
        CONSOLE_MODE.ENABLE_LINE_INPUT |
        CONSOLE_MODE.ENABLE_MOUSE_INPUT |
        CONSOLE_MODE.ENABLE_PROCESSED_INPUT |
        CONSOLE_MODE.ENABLE_QUICK_EDIT_MODE |
        CONSOLE_MODE.ENABLE_VIRTUAL_TERMINAL_INPUT;
    SetConsoleMode(inputHandle, dwMode);
  }
}
