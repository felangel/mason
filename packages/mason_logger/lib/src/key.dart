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

/// A representation of a keystroke.
class Key {
  bool isControl = false;
  String char = '';
  ControlCharacter controlChar = ControlCharacter.unknown;

  Key.printable(this.char) : assert(char.length == 1) {
    controlChar = ControlCharacter.none;
  }

  Key.control(this.controlChar) {
    char = '';
    isControl = true;
  }

  @override
  String toString() => isControl ? controlChar.toString() : char.toString();
}

Key readKey() {
  Key key;
  int charCode;
  var codeUnit = 0;

  while (codeUnit <= 0) {
    codeUnit = stdin.readByteSync();
  }

  if (codeUnit >= 0x01 && codeUnit <= 0x1a) {
    // Ctrl+A thru Ctrl+Z are mapped to the 1st-26th entries in the
    // enum, so it's easy to convert them across
    key = Key.control(ControlCharacter.values[codeUnit]);
  } else if (codeUnit == 0x1b) {
    // escape sequence (e.g. \x1b[A for up arrow)
    key = Key.control(ControlCharacter.escape);

    final escapeSequence = <String>[];

    charCode = stdin.readByteSync();
    if (charCode == -1) {
      return key;
    }
    escapeSequence.add(String.fromCharCode(charCode));

    if (charCode == 127) {
      key = Key.control(ControlCharacter.wordBackspace);
    } else if (escapeSequence[0] == '[') {
      charCode = stdin.readByteSync();
      if (charCode == -1) {
        return key;
      }
      escapeSequence.add(String.fromCharCode(charCode));

      switch (escapeSequence[1]) {
        case 'A':
          key.controlChar = ControlCharacter.arrowUp;
          break;
        case 'B':
          key.controlChar = ControlCharacter.arrowDown;
          break;
        case 'C':
          key.controlChar = ControlCharacter.arrowRight;
          break;
        case 'D':
          key.controlChar = ControlCharacter.arrowLeft;
          break;
        case 'H':
          key.controlChar = ControlCharacter.home;
          break;
        case 'F':
          key.controlChar = ControlCharacter.end;
          break;
        default:
          if (escapeSequence[1].codeUnits[0] > '0'.codeUnits[0] &&
              escapeSequence[1].codeUnits[0] < '9'.codeUnits[0]) {
            charCode = stdin.readByteSync();
            if (charCode == -1) {
              return key;
            }
            escapeSequence.add(String.fromCharCode(charCode));
            if (escapeSequence[2] != '~') {
              key.controlChar = ControlCharacter.unknown;
            } else {
              switch (escapeSequence[1]) {
                case '1':
                  key.controlChar = ControlCharacter.home;
                  break;
                case '3':
                  key.controlChar = ControlCharacter.delete;
                  break;
                case '4':
                  key.controlChar = ControlCharacter.end;
                  break;
                case '5':
                  key.controlChar = ControlCharacter.pageUp;
                  break;
                case '6':
                  key.controlChar = ControlCharacter.pageDown;
                  break;
                case '7':
                  key.controlChar = ControlCharacter.home;
                  break;
                case '8':
                  key.controlChar = ControlCharacter.end;
                  break;
                default:
                  key.controlChar = ControlCharacter.unknown;
              }
            }
          } else {
            key.controlChar = ControlCharacter.unknown;
          }
      }
    } else if (escapeSequence[0] == 'O') {
      charCode = stdin.readByteSync();
      if (charCode == -1) {
        return key;
      }
      escapeSequence.add(String.fromCharCode(charCode));
      assert(escapeSequence.length == 2);
      switch (escapeSequence[1]) {
        case 'H':
          key.controlChar = ControlCharacter.home;
          break;
        case 'F':
          key.controlChar = ControlCharacter.end;
          break;
        case 'P':
          key.controlChar = ControlCharacter.F1;
          break;
        case 'Q':
          key.controlChar = ControlCharacter.F2;
          break;
        case 'R':
          key.controlChar = ControlCharacter.F3;
          break;
        case 'S':
          key.controlChar = ControlCharacter.F4;
          break;
        default:
      }
    } else if (escapeSequence[0] == 'b') {
      key.controlChar = ControlCharacter.wordLeft;
    } else if (escapeSequence[0] == 'f') {
      key.controlChar = ControlCharacter.wordRight;
    } else {
      key.controlChar = ControlCharacter.unknown;
    }
  } else if (codeUnit == 0x7f) {
    key = Key.control(ControlCharacter.backspace);
  } else if (codeUnit == 0x00 || (codeUnit >= 0x1c && codeUnit <= 0x1f)) {
    key = Key.control(ControlCharacter.unknown);
  } else {
    // assume other characters are printable
    key = Key.printable(String.fromCharCode(codeUnit));
  }
  return key;
}
