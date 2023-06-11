// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

/// Exit code constants.
///
/// [Source](https://www.freebsd.org/cgi/man.cgi?query=sysexits).
// ignore: use_enums
class ExitCode {
  const ExitCode._(this.code, this._name);

  /// Command completed successfully.
  static const success = ExitCode._(0, 'success');

  /// Command was used incorrectly.
  ///
  /// This may occur if the wrong number of arguments was used, a bad flag, or
  /// bad syntax in a parameter.
  static const usage = ExitCode._(64, 'usage');

  /// Input data was used incorrectly.
  ///
  /// This should occur only for user data (not system files).
  static const data = ExitCode._(65, 'data');

  /// An input file (not a system file) did not exist or was not readable.
  static const noInput = ExitCode._(66, 'noInput');

  /// User specified did not exist.
  static const noUser = ExitCode._(67, 'noUser');

  /// Host specified did not exist.
  static const noHost = ExitCode._(68, 'noHost');

  /// A service is unavailable.
  ///
  /// This may occur if a support program or file does not exist. This may also
  /// be used as a catch-all error when something you wanted to do does not
  /// work, but you do not know why.
  static const unavailable = ExitCode._(69, 'unavailable');

  /// An internal software error has been detected.
  ///
  /// This should be limited to non-operating system related errors as possible.
  static const software = ExitCode._(70, 'software');

  /// An operating system error has been detected.
  ///
  /// This intended to be used for such thing as `cannot fork` or `cannot pipe`.
  static const osError = ExitCode._(71, 'osError');

  /// Some system file (e.g. `/etc/passwd`) does not exist or could not be read.
  static const osFile = ExitCode._(72, 'osFile');

  /// A (user specified) output file cannot be created.
  static const cantCreate = ExitCode._(73, 'cantCreate');

  /// An error occurred doing I/O on some file.
  static const ioError = ExitCode._(74, 'ioError');

  /// Temporary failure, indicating something is not really an error.
  ///
  /// In some cases, this can be re-attempted and will succeed later.
  static const tempFail = ExitCode._(75, 'tempFail');

  /// You did not have sufficient permissions to perform the operation.
  ///
  /// This is not intended for file system problems, which should use [noInput]
  /// or [cantCreate], but rather for higher-level permissions.
  static const noPerm = ExitCode._(77, 'noPerm');

  /// Something was found in an unconfigured or misconfigured state.
  static const config = ExitCode._(78, 'config');

  /// Exit code value.
  final int code;

  /// Name of the exit code.
  final String _name;

  @override
  String toString() => '$_name: $code';
}

const _ansiEscapeLiteral = '\x1B';
const _ansiEscapeForScript = r'\033';

/// Whether formatted ANSI output is enabled for [AnsiCode.wrap].
///
/// By default, returns `true` if both `stdout.supportsAnsiEscapes` and
/// `stderr.supportsAnsiEscapes` from `dart:io` are `true`.
///
/// The default can be overridden by setting the [Zone] variable [AnsiCode] to
/// either `true` or `false`.
///
bool get ansiOutputEnabled =>
    Zone.current[AnsiCode] as bool? ??
    (stdout.supportsAnsiEscapes && stderr.supportsAnsiEscapes);

/// Returns `true` no formatting is required for [input].
bool _isNoop(bool skip, String? input, bool? forScript) =>
    skip ||
    input == null ||
    input.isEmpty ||
    !((forScript ?? false) || ansiOutputEnabled);

/// Allows overriding [ansiOutputEnabled] to [enableAnsiOutput] for the code run
/// within [body].
// ignore: avoid_positional_boolean_parameters
T overrideAnsiOutput<T>(bool enableAnsiOutput, T Function() body) =>
    runZoned(body, zoneValues: <Object, Object>{AnsiCode: enableAnsiOutput});

/// The type of code represented by [AnsiCode].
// ignore: use_enums
class AnsiCodeType {
  const AnsiCodeType._(this._name);

  final String _name;

  /// A foreground color.
  static const AnsiCodeType foreground = AnsiCodeType._('foreground');

  /// A style.
  static const AnsiCodeType style = AnsiCodeType._('style');

  /// A background color.
  static const AnsiCodeType background = AnsiCodeType._('background');

  /// A reset value.
  static const AnsiCodeType reset = AnsiCodeType._('reset');

  @override
  String toString() => 'AnsiType.$_name';
}

/// Standard ANSI escape code for customizing terminal text output.
///
/// [Source](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors)
class AnsiCode {
  const AnsiCode._(this.name, this.type, this.code, this.reset);

  /// The numeric value associated with this code.
  final int code;

  /// The [AnsiCode] that resets this value, if one exists.
  ///
  /// Otherwise, `null`.
  final AnsiCode? reset;

  /// A description of this code.
  final String name;

  /// The type of code that is represented.
  final AnsiCodeType type;

  /// Represents the value escaped for use in terminal output.
  String get escape => '$_ansiEscapeLiteral[${code}m';

  /// Represents the value as an unescaped literal suitable for scripts.
  String get escapeForScript => '$_ansiEscapeForScript[${code}m';

  String _escapeValue({bool forScript = false}) =>
      forScript ? escapeForScript : escape;

  /// Wraps [value] with the [escape] value for this code, followed by
  /// [resetAll].
  ///
  /// If [forScript] is `true`, the return value is an unescaped literal. The
  /// value of [ansiOutputEnabled] is also ignored.
  ///
  /// Returns `value` unchanged if
  ///   * [value] is `null` or empty
  ///   * both [ansiOutputEnabled] and [forScript] are `false`.
  ///   * [type] is [AnsiCodeType.reset]
  String? wrap(String? value, {bool forScript = false}) =>
      _isNoop(type == AnsiCodeType.reset, value, forScript)
          ? value
          : '${_escapeValue(forScript: forScript)}$value'
              '${reset!._escapeValue(forScript: forScript)}';

  @override
  String toString() => '$name ${type._name} ($code)';
}

/// bold
const styleBold = AnsiCode._('bold', AnsiCodeType.style, 1, resetBold);

/// dim
const styleDim = AnsiCode._('dim', AnsiCodeType.style, 2, resetDim);

/// italic
const styleItalic = AnsiCode._('italic', AnsiCodeType.style, 3, resetItalic);

/// underlined
const styleUnderlined =
    AnsiCode._('underlined', AnsiCodeType.style, 4, resetUnderlined);

/// blink
const styleBlink = AnsiCode._('blink', AnsiCodeType.style, 5, resetBlink);

/// reverse
const styleReverse = AnsiCode._('reverse', AnsiCodeType.style, 7, resetReverse);

/// Reset values
const resetAll = AnsiCode._('all', AnsiCodeType.reset, 0, null);

/// Reset Bold
/// NOTE: bold is weird. The reset code seems to be 22 sometimes – not 21
/// See https://gitlab.com/gnachman/iterm2/issues/3208
const resetBold = AnsiCode._('bold', AnsiCodeType.reset, 22, null);

/// Reset Dim
const resetDim = AnsiCode._('dim', AnsiCodeType.reset, 22, null);

/// Reset Italic
const resetItalic = AnsiCode._('italic', AnsiCodeType.reset, 23, null);

/// Reset Underlined
const resetUnderlined = AnsiCode._('underlined', AnsiCodeType.reset, 24, null);

/// Reset Blink
const resetBlink = AnsiCode._('blink', AnsiCodeType.reset, 25, null);

/// Reset Reverse
const resetReverse = AnsiCode._('reverse', AnsiCodeType.reset, 27, null);

/// Foreground black
const black = AnsiCode._('black', AnsiCodeType.foreground, 30, resetAll);

/// Foreground red
const red = AnsiCode._('red', AnsiCodeType.foreground, 31, resetAll);

/// Foreground green
const green = AnsiCode._('green', AnsiCodeType.foreground, 32, resetAll);

/// Foreground yellow
const yellow = AnsiCode._('yellow', AnsiCodeType.foreground, 33, resetAll);

/// Foreground blue
const blue = AnsiCode._('blue', AnsiCodeType.foreground, 34, resetAll);

/// Foreground magenta
const magenta = AnsiCode._('magenta', AnsiCodeType.foreground, 35, resetAll);

/// Foreground cyan
const cyan = AnsiCode._('cyan', AnsiCodeType.foreground, 36, resetAll);

/// Foreground light gray
const lightGray =
    AnsiCode._('light gray', AnsiCodeType.foreground, 37, resetAll);

/// Foreground default
const defaultForeground =
    AnsiCode._('default', AnsiCodeType.foreground, 39, resetAll);

/// Foreground dark gray
const darkGray = AnsiCode._('dark gray', AnsiCodeType.foreground, 90, resetAll);

/// Foreground light red
const lightRed = AnsiCode._('light red', AnsiCodeType.foreground, 91, resetAll);

/// Foreground light green
const lightGreen =
    AnsiCode._('light green', AnsiCodeType.foreground, 92, resetAll);

/// Foreground yellow
const lightYellow =
    AnsiCode._('light yellow', AnsiCodeType.foreground, 93, resetAll);

/// Foreground blue
const lightBlue =
    AnsiCode._('light blue', AnsiCodeType.foreground, 94, resetAll);

/// Foreground magenta
const lightMagenta =
    AnsiCode._('light magenta', AnsiCodeType.foreground, 95, resetAll);

/// Foreground cyan
const lightCyan =
    AnsiCode._('light cyan', AnsiCodeType.foreground, 96, resetAll);

/// Foreground white
const white = AnsiCode._('white', AnsiCodeType.foreground, 97, resetAll);

/// Background black
const backgroundBlack =
    AnsiCode._('black', AnsiCodeType.background, 40, resetAll);

/// Background red
const backgroundRed = AnsiCode._('red', AnsiCodeType.background, 41, resetAll);

/// Background green
const backgroundGreen =
    AnsiCode._('green', AnsiCodeType.background, 42, resetAll);

/// Background yellow
const backgroundYellow =
    AnsiCode._('yellow', AnsiCodeType.background, 43, resetAll);

/// Background blue
const backgroundBlue =
    AnsiCode._('blue', AnsiCodeType.background, 44, resetAll);

/// Background magenta
const backgroundMagenta =
    AnsiCode._('magenta', AnsiCodeType.background, 45, resetAll);

/// Background cyan
const backgroundCyan =
    AnsiCode._('cyan', AnsiCodeType.background, 46, resetAll);

/// Background light gray
const backgroundLightGray =
    AnsiCode._('light gray', AnsiCodeType.background, 47, resetAll);

/// Background default
const backgroundDefault =
    AnsiCode._('default', AnsiCodeType.background, 49, resetAll);

/// Background dark gray
const backgroundDarkGray =
    AnsiCode._('dark gray', AnsiCodeType.background, 100, resetAll);

/// Background light red
const backgroundLightRed =
    AnsiCode._('light red', AnsiCodeType.background, 101, resetAll);

/// Background light green
const backgroundLightGreen =
    AnsiCode._('light green', AnsiCodeType.background, 102, resetAll);

/// Background light yellow
const backgroundLightYellow =
    AnsiCode._('light yellow', AnsiCodeType.background, 103, resetAll);

/// Background light blue
const backgroundLightBlue =
    AnsiCode._('light blue', AnsiCodeType.background, 104, resetAll);

/// Background light magenta
const backgroundLightMagenta =
    AnsiCode._('light magenta', AnsiCodeType.background, 105, resetAll);

/// Background light cyan
const backgroundLightCyan =
    AnsiCode._('light cyan', AnsiCodeType.background, 106, resetAll);

/// Background white
const backgroundWhite =
    AnsiCode._('white', AnsiCodeType.background, 107, resetAll);

/// All of the [AnsiCode] values that represent [AnsiCodeType.style].
const List<AnsiCode> styles = [
  styleBold,
  styleDim,
  styleItalic,
  styleUnderlined,
  styleBlink,
  styleReverse,
];

/// All of the [AnsiCode] values that represent [AnsiCodeType.foreground].
const List<AnsiCode> foregroundColors = [
  black,
  red,
  green,
  yellow,
  blue,
  magenta,
  cyan,
  lightGray,
  defaultForeground,
  darkGray,
  lightRed,
  lightGreen,
  lightYellow,
  lightBlue,
  lightMagenta,
  lightCyan,
  white
];

/// All of the [AnsiCode] values that represent [AnsiCodeType.background].
const List<AnsiCode> backgroundColors = [
  backgroundBlack,
  backgroundRed,
  backgroundGreen,
  backgroundYellow,
  backgroundBlue,
  backgroundMagenta,
  backgroundCyan,
  backgroundLightGray,
  backgroundDefault,
  backgroundDarkGray,
  backgroundLightRed,
  backgroundLightGreen,
  backgroundLightYellow,
  backgroundLightBlue,
  backgroundLightMagenta,
  backgroundLightCyan,
  backgroundWhite
];

/// Non-printable characters that can be entered from the keyboard.
///
enum ControlCharacter {
  /// null
  none,

  /// Start of heading
  ctrlA,

  /// Start of text
  ctrlB,

  /// End of text
  ctrlC,

  /// End of xmit/file
  ctrlD,

  /// Enquiry
  ctrlE,

  /// Acknowledge
  ctrlF,

  /// Bell
  ctrlG,

  /// Backspace
  ctrlH,

  /// Horizontal tab
  ctrlI,

  /// Line feed (return)
  ctrlJ,

  /// Vertical tab
  ctrlK,

  /// Form feed
  ctrlL,

  /// Carriage feed (enter)
  ctrlM,

  /// Shift out
  ctrlN,

  /// Shift in
  ctrlO,

  /// Data line escape
  ctrlP,

  /// Device control 1
  ctrlQ,

  /// Device control 2
  ctrlR,

  /// Device control 3
  ctrlS,

  /// Device control 4
  ctrlT,

  /// Neg acknowledge
  ctrlU,

  /// Syncronous idel
  ctrlV,

  /// End of xmit block
  ctrlW,

  /// Cancel
  ctrlX,

  /// End of medium
  ctrlY,

  /// Substitue (suspend)
  ctrlZ,

  /// Left arrow
  arrowLeft,

  /// Right arrow
  arrowRight,

  /// Up arrow
  arrowUp,

  /// Down arrow
  arrowDown,

  /// Page up
  pageUp,

  /// Page down
  pageDown,

  /// Word left
  wordLeft,

  /// Word right
  wordRight,

  /// Home
  home,

  /// End
  end,

  /// Escape
  escape,

  /// Delete
  delete,

  /// Backspace
  backspace,

  /// Word backspace
  wordBackspace,

  /// Function 1
  // ignore: constant_identifier_names
  F1,

  /// Function 2
  // ignore: constant_identifier_names
  F2,

  /// Function 3
  // ignore: constant_identifier_names
  F3,

  /// Function 4
  // ignore: constant_identifier_names
  F4,

  /// Unknown control character
  unknown
}

/// {@template key_stroke}
/// A representation of a keystroke.
/// {@endtemplate}
class KeyStroke {
  /// {@macro key_stroke}
  const KeyStroke({
    this.char = '',
    this.controlChar = ControlCharacter.unknown,
  });

  /// {@macro key_stroke}
  factory KeyStroke.char(String char) {
    assert(char.length == 1, 'characters must be a single unit');
    return KeyStroke(
      char: char,
      controlChar: ControlCharacter.none,
    );
  }

  /// {@macro key_stroke}
  factory KeyStroke.control(ControlCharacter controlChar) {
    return KeyStroke(controlChar: controlChar);
  }

  /// The printable character.
  final String char;

  /// The control character value.
  final ControlCharacter controlChar;

  /// Copy the current [KeyStroke] and optionally
  /// override either [char] or [controlChar].
  KeyStroke copyWith({String? char, ControlCharacter? controlChar}) {
    return KeyStroke(
      char: char ?? this.char,
      controlChar: controlChar ?? this.controlChar,
    );
  }
}

/// Read key stroke from stdin.
KeyStroke readKeyStroke() {
  KeyStroke keyStroke;
  int charCode;
  var codeUnit = 0;

  while (codeUnit <= 0) {
    codeUnit = stdin.readByteSync();
  }

  if (codeUnit >= 0x01 && codeUnit <= 0x1a) {
    // Ctrl+A thru Ctrl+Z are mapped to the 1st-26th entries in the
    // enum, so it's easy to convert them across
    keyStroke = KeyStroke.control(ControlCharacter.values[codeUnit]);
  } else if (codeUnit == 0x1b) {
    // escape sequence (e.g. \x1b[A for up arrow)
    keyStroke = KeyStroke.control(ControlCharacter.escape);

    final escapeSequence = <String>[];

    charCode = stdin.readByteSync();
    if (charCode == -1) return keyStroke;

    escapeSequence.add(String.fromCharCode(charCode));

    if (charCode == 127) {
      keyStroke = KeyStroke.control(ControlCharacter.wordBackspace);
    } else if (escapeSequence[0] == '[') {
      charCode = stdin.readByteSync();
      if (charCode == -1) return keyStroke;

      escapeSequence.add(String.fromCharCode(charCode));

      switch (escapeSequence[1]) {
        case 'A':
          keyStroke = keyStroke.copyWith(controlChar: ControlCharacter.arrowUp);
          break;
        case 'B':
          keyStroke =
              keyStroke.copyWith(controlChar: ControlCharacter.arrowDown);
          break;
        case 'C':
          keyStroke =
              keyStroke.copyWith(controlChar: ControlCharacter.arrowRight);
          break;
        case 'D':
          keyStroke =
              keyStroke.copyWith(controlChar: ControlCharacter.arrowLeft);
          break;
        case 'H':
          keyStroke = keyStroke.copyWith(controlChar: ControlCharacter.home);
          break;
        case 'F':
          keyStroke = keyStroke.copyWith(controlChar: ControlCharacter.end);
          break;
        default:
          if (escapeSequence[1].codeUnits[0] > '0'.codeUnits[0] &&
              escapeSequence[1].codeUnits[0] < '9'.codeUnits[0]) {
            charCode = stdin.readByteSync();
            if (charCode == -1) return keyStroke;

            escapeSequence.add(String.fromCharCode(charCode));
            if (escapeSequence[2] != '~') {
              keyStroke = keyStroke.copyWith(
                controlChar: ControlCharacter.unknown,
              );
            } else {
              switch (escapeSequence[1]) {
                case '1':
                  keyStroke = keyStroke.copyWith(
                    controlChar: ControlCharacter.home,
                  );
                  break;
                case '3':
                  keyStroke = keyStroke.copyWith(
                    controlChar: ControlCharacter.delete,
                  );
                  break;
                case '4':
                  keyStroke = keyStroke.copyWith(
                    controlChar: ControlCharacter.end,
                  );
                  break;
                case '5':
                  keyStroke = keyStroke.copyWith(
                    controlChar: ControlCharacter.pageUp,
                  );
                  break;
                case '6':
                  keyStroke = keyStroke.copyWith(
                    controlChar: ControlCharacter.pageDown,
                  );
                  break;
                case '7':
                  keyStroke = keyStroke.copyWith(
                    controlChar: ControlCharacter.home,
                  );
                  break;
                case '8':
                  keyStroke = keyStroke.copyWith(
                    controlChar: ControlCharacter.end,
                  );
                  break;
                default:
                  keyStroke = keyStroke.copyWith(
                    controlChar: ControlCharacter.unknown,
                  );
              }
            }
          } else {
            keyStroke = keyStroke.copyWith(
              controlChar: ControlCharacter.unknown,
            );
          }
      }
    } else if (escapeSequence[0] == 'O') {
      charCode = stdin.readByteSync();
      if (charCode == -1) return keyStroke;
      escapeSequence.add(String.fromCharCode(charCode));
      assert(
        escapeSequence.length == 2,
        'escape sequence consist of 2 characters',
      );
      switch (escapeSequence[1]) {
        case 'H':
          keyStroke = keyStroke.copyWith(controlChar: ControlCharacter.home);
          break;
        case 'F':
          keyStroke = keyStroke.copyWith(controlChar: ControlCharacter.end);
          break;
        case 'P':
          keyStroke = keyStroke.copyWith(controlChar: ControlCharacter.F1);
          break;
        case 'Q':
          keyStroke = keyStroke.copyWith(controlChar: ControlCharacter.F2);
          break;
        case 'R':
          keyStroke = keyStroke.copyWith(controlChar: ControlCharacter.F3);
          break;
        case 'S':
          keyStroke = keyStroke.copyWith(controlChar: ControlCharacter.F4);
          break;
        default:
      }
    } else if (escapeSequence[0] == 'b') {
      keyStroke = keyStroke.copyWith(controlChar: ControlCharacter.wordLeft);
    } else if (escapeSequence[0] == 'f') {
      keyStroke = keyStroke.copyWith(controlChar: ControlCharacter.wordRight);
    } else {
      keyStroke = keyStroke.copyWith(controlChar: ControlCharacter.unknown);
    }
  } else if (codeUnit == 0x7f) {
    keyStroke = KeyStroke.control(ControlCharacter.backspace);
  } else if (codeUnit == 0x00 || (codeUnit >= 0x1c && codeUnit <= 0x1f)) {
    keyStroke = KeyStroke.control(ControlCharacter.unknown);
  } else {
    // assume other characters are printable
    keyStroke = KeyStroke.char(String.fromCharCode(codeUnit));
  }
  return keyStroke;
}
