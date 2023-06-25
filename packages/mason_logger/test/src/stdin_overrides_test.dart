import 'package:mason_logger/src/io.dart';
import 'package:mason_logger/src/stdin_overrides.dart';
import 'package:test/test.dart';

void main() {
  group(StdinOverrides, () {
    group('runZoned', () {
      test('uses default readKey when not specified', () {
        StdinOverrides.runZoned(() {
          final overrides = StdinOverrides.current;
          expect(overrides!.readKey, isNotNull);
        });
      });

      test('uses custom readKey when specified', () {
        StdinOverrides.runZoned(
          () {
            final overrides = StdinOverrides.current;
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
        StdinOverrides.runZoned(
          () {
            StdinOverrides.runZoned(() {
              final overrides = StdinOverrides.current;
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
        StdinOverrides.runZoned(
          () {
            KeyStroke nestedReadKey() => KeyStroke.char('b');
            final overrides = StdinOverrides.current;
            expect(
              overrides!.readKey(),
              isA<KeyStroke>().having((s) => s.char, 'char', 'a'),
            );
            StdinOverrides.runZoned(
              () {
                final overrides = StdinOverrides.current;
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
    });
  });
}
