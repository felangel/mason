import 'dart:io';

import 'package:mason_logger/src/io.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockStdin extends Mock implements Stdin {}

void main() {
  group('io', () {
    group('KeyStroke', () {
      late Stdin stdin;

      setUp(() {
        stdin = _MockStdin();
      });

      group('readKey', () {
        test('returns regular char', () {
          IOOverrides.runZoned(
            () {
              when(() => stdin.readByteSync()).thenReturn('a'.codeUnits.first);
              expect(
                readKey(),
                isA<KeyStroke>().having((s) => s.char, 'char', 'a'),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns Ctrl+A control character for 0x01', () {
          IOOverrides.runZoned(
            () {
              when(() => stdin.readByteSync()).thenReturn(0x01);
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.ctrlA,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns wordBackspace', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, 127, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.wordBackspace,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns arrowUp for [A', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[A'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.arrowUp,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns arrowDown for [B', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[B'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.arrowDown,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns arrowRight for [C', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[C'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.arrowRight,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns arrowLeft for [D', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[D'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.arrowLeft,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns home for [H', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[H'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.home,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns end for [F', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[F'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.end,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns home for [1~', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[1~'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.home,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns delete for [3~', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[3~'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.delete,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns end for [4~', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[4~'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.end,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns pageUp for [5~', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[5~'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.pageUp,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns pageDown for [6~', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[6~'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.pageDown,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns home for [7~', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[7~'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.home,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns end for [8~', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[8~'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.end,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns unknown for [2~', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[2~'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.unknown,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns unknown for [9~', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[9~'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.unknown,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns end for 0x1b OF', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'OF'.codeUnits, 0x1b, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.end,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns home for 0x1b OH', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'OH'.codeUnits, 0x1b, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.home,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns F1 for 0x1b OP', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'OP'.codeUnits, 0x1b, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.F1,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns F2 for 0x1b OQ', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'OQ'.codeUnits, 0x1b, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.F2,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns F3 for 0x1b OR', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'OR'.codeUnits, 0x1b, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.F3,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns F4 for 0x1b OS', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'OS'.codeUnits, 0x1b, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.F4,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns wordLeft for 0x1b b', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'b'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.wordLeft,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns wordRight for 0x1b f', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'f'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.wordRight,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns unknown for 0x1b z', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'z'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.unknown,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns unknown for garbage', () {
          IOOverrides.runZoned(
            () {
              final charCodes = [0x1b, ...'[1!'.codeUnits, -1];
              when(
                () => stdin.readByteSync(),
              ).thenAnswer((_) => charCodes.removeAt(0));
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.unknown,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns backspace control character for 0x7f', () {
          IOOverrides.runZoned(
            () {
              when(() => stdin.readByteSync()).thenReturn(0x7f);
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.backspace,
                ),
              );
            },
            stdin: () => stdin,
          );
        });

        test('returns unknown control character for 0x1c', () {
          IOOverrides.runZoned(
            () {
              when(() => stdin.readByteSync()).thenReturn(0x1c);
              expect(
                readKey(),
                isA<KeyStroke>().having(
                  (s) => s.controlChar,
                  'controlChar',
                  ControlCharacter.unknown,
                ),
              );
            },
            stdin: () => stdin,
          );
        });
      });
    });
  });
}
