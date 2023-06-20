import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mason_logger/src/io.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockStdin extends Mock implements Stdin {}

void main() {
  group('io', () {
    group('ExitCode', () {
      test('overrides toString()', () {
        expect(ExitCode.success.toString(), equals('success: 0'));
      });
    });

    group('AnsiCodeType', () {
      test('overrides toString()', () {
        expect(
          AnsiCodeType.reset.toString(),
          equals('AnsiType.reset'),
        );
        expect(
          AnsiCodeType.background.toString(),
          equals('AnsiType.background'),
        );
        expect(
          AnsiCodeType.foreground.toString(),
          equals('AnsiType.foreground'),
        );
        expect(
          AnsiCodeType.style.toString(),
          equals('AnsiType.style'),
        );
      });
    });

    group('AnsiCode', () {
      test('overrides toString()', () {
        expect(yellow.toString(), equals('yellow foreground (33)'));
      });

      for (final forScript in [true, false]) {
        group(forScript ? 'forScript' : 'escaped', () {
          const ansiEscapeLiteral = '\x1B';
          const ansiEscapeForScript = r'\033';
          const sampleInput = 'sample input';

          final escapeLiteral =
              forScript ? ansiEscapeForScript : ansiEscapeLiteral;

          group('.wrap', () {
            _test('color', () {
              final expected =
                  '$escapeLiteral[34m$sampleInput$escapeLiteral[0m';

              expect(blue.wrap(sampleInput, forScript: forScript), expected);
            });

            _test('style', () {
              final expected =
                  '$escapeLiteral[1m$sampleInput$escapeLiteral[22m';

              expect(
                styleBold.wrap(sampleInput, forScript: forScript),
                expected,
              );
            });

            _test('style', () {
              final expected =
                  '$escapeLiteral[34m$sampleInput$escapeLiteral[0m';

              expect(blue.wrap(sampleInput, forScript: forScript), expected);
            });

            _test('empty', () {
              expect(blue.wrap('', forScript: forScript), '');
            });

            _test('null', () {
              expect(blue.wrap(null, forScript: forScript), isNull);
            });
          });
        });
      }
    });

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

@isTest
void _test<T>(String name, T Function() body) {
  test(name, () => overrideAnsiOutput<T>(true, body));
}
