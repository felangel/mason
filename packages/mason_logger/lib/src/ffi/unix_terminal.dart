// coverage:ignore-file
// ignore_for_file: public_member_api_docs, constant_identifier_names, camel_case_types, non_constant_identifier_names, lines_longer_than_80_chars

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:mason_logger/src/ffi/terminal.dart';

class UnixTerminal implements Terminal {
  UnixTerminal() {
    _lib = Platform.isMacOS
        ? DynamicLibrary.open('/usr/lib/libSystem.dylib')
        : DynamicLibrary.open('libc.so.6');

    _tcgetattr = _lib.lookupFunction<TCGetAttrNative, TCGetAttrDart>(
      'tcgetattr',
    );
    _tcsetattr = _lib.lookupFunction<TCSetAttrNative, TCSetAttrDart>(
      'tcsetattr',
    );

    _origTermIOSPointer = calloc<TermIOS>();
    _tcgetattr(_STDIN_FILENO, _origTermIOSPointer);
  }

  late final DynamicLibrary _lib;
  late final Pointer<TermIOS> _origTermIOSPointer;
  late final TCGetAttrDart _tcgetattr;
  late final TCSetAttrDart _tcsetattr;

  @override
  void enableRawMode() {
    final origTermIOS = _origTermIOSPointer.ref;
    final newTermIOSPointer = calloc<TermIOS>()
      ..ref.c_iflag =
          origTermIOS.c_iflag & ~(_BRKINT | _ICRNL | _INPCK | _ISTRIP | _IXON)
      ..ref.c_oflag = origTermIOS.c_oflag & ~_OPOST
      ..ref.c_cflag = (origTermIOS.c_cflag & ~_CSIZE) | _CS8
      ..ref.c_lflag = origTermIOS.c_lflag & ~(_ECHO | _ICANON | _IEXTEN | _ISIG)
      ..ref.c_cc = origTermIOS.c_cc
      ..ref.c_cc[_VMIN] = 0
      ..ref.c_cc[_VTIME] = 1
      ..ref.c_ispeed = origTermIOS.c_ispeed
      ..ref.c_oflag = origTermIOS.c_ospeed;

    _tcsetattr(_STDIN_FILENO, _TCSANOW, newTermIOSPointer);
    calloc.free(newTermIOSPointer);
  }

  @override
  void disableRawMode() {
    if (nullptr == _origTermIOSPointer.cast()) return;
    _tcsetattr(_STDIN_FILENO, _TCSANOW, _origTermIOSPointer);
  }
}

// Input Modes
// https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.3/html_node/libc_352.html
const int _BRKINT = 0x00000002;
const int _INPCK = 0x00000010;
const int _ISTRIP = 0x00000020;
const int _ICRNL = 0x00000100;
const int _IXON = 0x00000200;

// Output Modes
// https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.3/html_node/libc_353.html#SEC362
const int _OPOST = 0x00000001;

// Control Modes
// https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.3/html_node/libc_354.html#SEC363
const int _CSIZE = 0x00000300;
const int _CS8 = 0x00000300;

// Local Modes
// https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.3/html_node/libc_355.html#SEC364
const int _ECHO = 0x00000008;
const int _ISIG = 0x00000080;
const int _ICANON = 0x00000100;
const int _IEXTEN = 0x00000400;
const int _TCSANOW = 0;
const int _VMIN = 16;
const int _VTIME = 17;

typedef tcflag_t = UnsignedLong;
typedef cc_t = UnsignedChar;
typedef speed_t = UnsignedLong;

// The default standard input file descriptor number which is 0.
const _STDIN_FILENO = 0;

// The number of elements in the control chars array.
const _NCSS = 20;

class TermIOS extends Struct {
  @tcflag_t()
  external int c_iflag; // input flags
  @tcflag_t()
  external int c_oflag; // output flags
  @tcflag_t()
  external int c_cflag; // control flags
  @tcflag_t()
  external int c_lflag; // local flags
  @Array(_NCSS)
  external Array<cc_t> c_cc; // control chars
  @speed_t()
  external int c_ispeed; // input speed
  @speed_t()
  external int c_ospeed; // output speed
}

// int tcgetattr(int, struct termios *);
typedef TCGetAttrNative = Int32 Function(
  Int32 fildes,
  Pointer<TermIOS> termios,
);
typedef TCGetAttrDart = int Function(int fildes, Pointer<TermIOS> termios);

// int tcsetattr(int, int, const struct termios *);
typedef TCSetAttrNative = Int32 Function(
  Int32 fildes,
  Int32 optional_actions,
  Pointer<TermIOS> termios,
);
typedef TCSetAttrDart = int Function(
  int fildes,
  int optional_actions,
  Pointer<TermIOS> termios,
);
