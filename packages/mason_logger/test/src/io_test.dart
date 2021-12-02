import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

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
          const _ansiEscapeLiteral = '\x1B';
          const _ansiEscapeForScript = r'\033';
          const sampleInput = 'sample input';

          final escapeLiteral =
              forScript ? _ansiEscapeForScript : _ansiEscapeLiteral;

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
  });
}

@isTest
void _test<T>(String name, T Function() body) {
  test(name, () => overrideAnsiOutput<T>(true, body));
}
