// coverage:ignore-file
// ignore_for_file: public_member_api_docs, constant_identifier_names, camel_case_types, non_constant_identifier_names, lines_longer_than_80_chars

// cspell:words tcgetattr BRKINT ICRNL INPCK ISTRIP IXON lflag CSIZE
// cspell:words fildes termios ospeed ispeed tcflag ncss vtime vmin cflag
// cspell:words icanon isig iexten tcsanow tcsetattr FILENO iflag oflag OPOST
// cspell:words glibc bionic VTIME VMIN

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

    _origTermIOSPointer = calloc<Uint8>(_termiosSize);
    _tcgetattr(_STDIN_FILENO, _origTermIOSPointer);
  }

  late final DynamicLibrary _lib;
  late final Pointer<Uint8> _origTermIOSPointer;
  late final TCGetAttrDart _tcgetattr;
  late final TCSetAttrDart _tcsetattr;

  final _termios = Platform.isMacOS || Platform.isIOS
      ? _TermIOSLayout.darwin
      : _TermIOSLayout.linux;

  @override
  void enableRawMode() {
    final t = _termios;
    // Start from a copy of the original settings, so that every field this
    // doesn't change (including ones that only some C libraries have) keeps
    // its value.
    final newTermIOSPointer = calloc<Uint8>(_termiosSize);
    newTermIOSPointer
        .asTypedList(_termiosSize)
        .setAll(0, _origTermIOSPointer.asTypedList(_termiosSize));
    t
      ..setFlags(
        newTermIOSPointer,
        _iflag,
        t.flags(newTermIOSPointer, _iflag) &
            ~(t.BRKINT | t.ICRNL | t.INPCK | t.ISTRIP | t.IXON),
      )
      ..setFlags(
        newTermIOSPointer,
        _oflag,
        t.flags(newTermIOSPointer, _oflag) & ~t.OPOST,
      )
      ..setFlags(
        newTermIOSPointer,
        _cflag,
        (t.flags(newTermIOSPointer, _cflag) & ~t.CSIZE) | t.CS8,
      )
      ..setFlags(
        newTermIOSPointer,
        _lflag,
        t.flags(newTermIOSPointer, _lflag) &
            ~(t.ECHO | t.ICANON | t.IEXTEN | t.ISIG),
      )
      ..setControlChar(newTermIOSPointer, t.VMIN, 0)
      ..setControlChar(newTermIOSPointer, t.VTIME, 1);

    _tcsetattr(_STDIN_FILENO, _TCSANOW, newTermIOSPointer);
    calloc.free(newTermIOSPointer);
  }

  @override
  void disableRawMode() {
    if (nullptr == _origTermIOSPointer.cast()) return;
    _tcsetattr(_STDIN_FILENO, _TCSANOW, _origTermIOSPointer);
  }
}

/// The layout of `struct termios` and the values of its flags, which differ
/// between platforms.
///
/// The struct is handled as raw bytes, because its size and its fields after
/// the control characters also differ between C libraries on the same
/// platform (glibc and bionic on Linux).
enum _TermIOSLayout {
  /// Linux and Android (glibc and bionic use the kernel's values): `tcflag_t`
  /// is a 32-bit `unsigned int`, and `c_cc` follows the four flag fields and
  /// `c_line`.
  linux(
    flagSize: 4,
    controlCharsOffset: 17,
    VMIN: 6,
    VTIME: 5,
    BRKINT: 0x00000002,
    INPCK: 0x00000010,
    ISTRIP: 0x00000020,
    ICRNL: 0x00000100,
    IXON: 0x00000400,
    OPOST: 0x00000001,
    CSIZE: 0x00000030,
    CS8: 0x00000030,
    ECHO: 0x00000008,
    ISIG: 0x00000001,
    ICANON: 0x00000002,
    IEXTEN: 0x00008000,
  ),

  /// macOS and iOS: `tcflag_t` is a 64-bit `unsigned long`, and `c_cc`
  /// follows the four flag fields.
  darwin(
    flagSize: 8,
    controlCharsOffset: 32,
    VMIN: 16,
    VTIME: 17,
    BRKINT: 0x00000002,
    INPCK: 0x00000010,
    ISTRIP: 0x00000020,
    ICRNL: 0x00000100,
    IXON: 0x00000200,
    OPOST: 0x00000001,
    CSIZE: 0x00000300,
    CS8: 0x00000300,
    ECHO: 0x00000008,
    ISIG: 0x00000080,
    ICANON: 0x00000100,
    IEXTEN: 0x00000400,
  );

  const _TermIOSLayout({
    required this.flagSize,
    required this.controlCharsOffset,
    required this.VMIN,
    required this.VTIME,
    required this.BRKINT,
    required this.INPCK,
    required this.ISTRIP,
    required this.ICRNL,
    required this.IXON,
    required this.OPOST,
    required this.CSIZE,
    required this.CS8,
    required this.ECHO,
    required this.ISIG,
    required this.ICANON,
    required this.IEXTEN,
  });

  /// The size of `tcflag_t`, the type of the four flag fields.
  final int flagSize;

  /// The offset of the control characters array `c_cc`.
  final int controlCharsOffset;

  // Indices into `c_cc`.
  final int VMIN;
  final int VTIME;

  // Input modes (`c_iflag`).
  final int BRKINT;
  final int INPCK;
  final int ISTRIP;
  final int ICRNL;
  final int IXON;

  // Output modes (`c_oflag`).
  final int OPOST;

  // Control modes (`c_cflag`).
  final int CSIZE;
  final int CS8;

  // Local modes (`c_lflag`).
  final int ECHO;
  final int ISIG;
  final int ICANON;
  final int IEXTEN;

  /// Reads flag field number [field] (one of [_iflag], [_oflag], [_cflag]
  /// and [_lflag]).
  int flags(Pointer<Uint8> termios, int field) => flagSize == 4
      ? termios.cast<Uint32>()[field]
      : termios.cast<Uint64>()[field];

  /// Writes flag field number [field].
  void setFlags(Pointer<Uint8> termios, int field, int value) {
    if (flagSize == 4) {
      termios.cast<Uint32>()[field] = value;
    } else {
      termios.cast<Uint64>()[field] = value;
    }
  }

  /// Sets control character [index] (e.g. [VMIN]) to [value].
  void setControlChar(Pointer<Uint8> termios, int index, int value) {
    termios[controlCharsOffset + index] = value;
  }
}

// The flag fields, in the order they appear in `struct termios`.
const _iflag = 0;
const _oflag = 1;
const _cflag = 2;
const _lflag = 3;

// Larger than `struct termios` on every supported platform (60 bytes with
// glibc, 36 with bionic, 72 on macOS).
const _termiosSize = 128;

const int _TCSANOW = 0;

// The default standard input file descriptor number which is 0.
const _STDIN_FILENO = 0;

// int tcgetattr(int, struct termios *);
typedef TCGetAttrNative = Int32 Function(Int32 fildes, Pointer<Uint8> termios);
typedef TCGetAttrDart = int Function(int fildes, Pointer<Uint8> termios);

// int tcsetattr(int, int, const struct termios *);
typedef TCSetAttrNative =
    Int32 Function(
      Int32 fildes,
      Int32 optional_actions,
      Pointer<Uint8> termios,
    );
typedef TCSetAttrDart =
    int Function(int fildes, int optional_actions, Pointer<Uint8> termios);
