import 'dart:io';

export 'package:io/io.dart' show ExitCode;

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

  /// Synchronous idle
  ctrlV,

  /// End of xmit block
  ctrlW,

  /// Cancel
  ctrlX,

  /// End of medium
  ctrlY,

  /// Substitute (suspend)
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
  unknown,
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
    return KeyStroke(char: char, controlChar: ControlCharacter.none);
  }

  /// {@macro key_stroke}
  factory KeyStroke.control(ControlCharacter controlChar) {
    return KeyStroke(controlChar: controlChar);
  }

  /// The printable character.
  final String char;

  /// The control character value.
  final ControlCharacter controlChar;
}

/// Read key stroke from stdin.
KeyStroke readKey() {
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
      // A control sequence: parameter and intermediate bytes (0x20-0x3F, e.g.
      // `1;5`), then one final byte (0x40-0x7E). Read all of it, so that the
      // rest of a sequence this doesn't recognize, such as Ctrl+Right
      // (`[1;5C`) or F5 (`[15~`), isn't read as typed characters.
      final parameters = StringBuffer();
      while (true) {
        charCode = stdin.readByteSync();
        if (charCode == -1) {
          if (parameters.isEmpty) return keyStroke;
          return KeyStroke.control(ControlCharacter.unknown);
        }
        if (charCode >= 0x40 && charCode <= 0x7e) break;
        if (charCode < 0x20 || charCode > 0x3f) {
          return KeyStroke.control(ControlCharacter.unknown);
        }
        parameters.writeCharCode(charCode);
      }

      keyStroke = KeyStroke.control(switch ((
        parameters.toString(),
        String.fromCharCode(charCode),
      )) {
        ('', 'A') => ControlCharacter.arrowUp,
        ('', 'B') => ControlCharacter.arrowDown,
        ('', 'C') => ControlCharacter.arrowRight,
        ('', 'D') => ControlCharacter.arrowLeft,
        ('', 'H') || ('1', '~') || ('7', '~') => ControlCharacter.home,
        ('', 'F') || ('4', '~') || ('8', '~') => ControlCharacter.end,
        ('3', '~') => ControlCharacter.delete,
        ('5', '~') => ControlCharacter.pageUp,
        ('6', '~') => ControlCharacter.pageDown,
        _ => ControlCharacter.unknown,
      });
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
          keyStroke = KeyStroke.control(ControlCharacter.home);
        case 'F':
          keyStroke = KeyStroke.control(ControlCharacter.end);
        case 'P':
          keyStroke = KeyStroke.control(ControlCharacter.F1);
        case 'Q':
          keyStroke = KeyStroke.control(ControlCharacter.F2);
        case 'R':
          keyStroke = KeyStroke.control(ControlCharacter.F3);
        case 'S':
          keyStroke = KeyStroke.control(ControlCharacter.F4);
        default:
      }
    } else if (escapeSequence[0] == 'b') {
      keyStroke = KeyStroke.control(ControlCharacter.wordLeft);
    } else if (escapeSequence[0] == 'f') {
      keyStroke = KeyStroke.control(ControlCharacter.wordRight);
    } else {
      keyStroke = KeyStroke.control(ControlCharacter.unknown);
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
