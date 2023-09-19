import 'package:mason_logger/src/ffi/terminal.dart';
import 'package:mason_logger/src/io.dart';
import 'package:mason_logger/src/terminal_overrides.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockTerminal extends Mock implements Terminal {}

void main() {
  group(TerminalOverrides, () {
    group('runZoned', () {
      test('uses default readKey when not specified', () {
        TerminalOverrides.runZoned(() {
          final overrides = TerminalOverrides.current;
          expect(overrides!.readKey, isNotNull);
        });
      });

      test('uses custom readKey when specified', () {
        TerminalOverrides.runZoned(
          () {
            final overrides = TerminalOverrides.current;
            expect(
              overrides!.readKey(),
              isA<KeyStroke>().having((s) => s.char, 'char', 'a'),
            );
          },
          readKey: () => KeyStroke.char('a'),
        );
      });

      test(
          'uses current readKey when not specified '
          'and zone already contains a readKey', () {
        TerminalOverrides.runZoned(
          () {
            TerminalOverrides.runZoned(() {
              final overrides = TerminalOverrides.current;
              expect(
                overrides!.readKey(),
                isA<KeyStroke>().having((s) => s.char, 'char', 'x'),
              );
            });
          },
          readKey: () => KeyStroke.char('x'),
        );
      });

      test(
          'uses nested readKey when specified '
          'and zone already contains a readKey', () {
        KeyStroke rootReadKey() => KeyStroke.char('a');
        TerminalOverrides.runZoned(
          () {
            KeyStroke nestedReadKey() => KeyStroke.char('b');
            final overrides = TerminalOverrides.current;
            expect(
              overrides!.readKey(),
              isA<KeyStroke>().having((s) => s.char, 'char', 'a'),
            );
            TerminalOverrides.runZoned(
              () {
                final overrides = TerminalOverrides.current;
                expect(
                  overrides!.readKey(),
                  isA<KeyStroke>().having((s) => s.char, 'char', 'b'),
                );
              },
              readKey: nestedReadKey,
            );
          },
          readKey: rootReadKey,
        );
      });

      test('uses default createTerminal when not specified', () {
        TerminalOverrides.runZoned(() {
          final overrides = TerminalOverrides.current;
          expect(overrides!.createTerminal, isNotNull);
        });
      });

      test('uses custom createTerminal when specified', () {
        final Terminal terminal = _MockTerminal();
        TerminalOverrides.runZoned(
          () {
            final overrides = TerminalOverrides.current;
            expect(
              overrides!.createTerminal(),
              equals(terminal),
            );
          },
          createTerminal: () => terminal,
        );
      });

      test(
          'uses current createTerminal when not specified '
          'and zone already contains a createTerminal', () {
        final Terminal terminal = _MockTerminal();
        TerminalOverrides.runZoned(
          () {
            TerminalOverrides.runZoned(() {
              final overrides = TerminalOverrides.current;
              expect(
                overrides!.createTerminal(),
                equals(terminal),
              );
            });
          },
          createTerminal: () => terminal,
        );
      });

      test(
          'uses nested readKey when specified '
          'and zone already contains a readKey', () {
        final Terminal rootTerminal = _MockTerminal();
        TerminalOverrides.runZoned(
          () {
            final Terminal nestedTerminal = _MockTerminal();
            final overrides = TerminalOverrides.current;
            expect(
              overrides!.createTerminal(),
              equals(rootTerminal),
            );
            TerminalOverrides.runZoned(
              () {
                final overrides = TerminalOverrides.current;
                expect(
                  overrides!.createTerminal(),
                  equals(nestedTerminal),
                );
              },
              createTerminal: () => nestedTerminal,
            );
          },
          createTerminal: () => rootTerminal,
        );
      });
    });
  });
}
