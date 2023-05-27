import 'dart:io';

/// Non-printable characters that can be entered from the keyboard.
enum ControlCharacter {
  none,
  ctrlA,
  ctrlB,
  ctrlC, // Break
  ctrlD, // End of File
  ctrlE,
  ctrlF,
  ctrlG, // Bell
  ctrlH, // Backspace
  tab,
  ctrlJ, // Return
  ctrlK,
  ctrlL,
  enter,
  ctrlN,
  ctrlO,
  ctrlP,
  ctrlQ,
  ctrlR,
  ctrlS,
  ctrlT,
  ctrlU,
  ctrlV,
  ctrlW,
  ctrlX,
  ctrlY,
  ctrlZ, // Suspend

  arrowLeft,
  arrowRight,
  arrowUp,
  arrowDown,
  pageUp,
  pageDown,
  wordLeft,
  wordRight,

  home,
  end,
  escape,
  delete,
  backspace,
  wordBackspace,

  // ignore: constant_identifier_names
  F1,
  // ignore: constant_identifier_names
  F2,
  // ignore: constant_identifier_names
  F3,
  // ignore: constant_identifier_names
  F4,

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
