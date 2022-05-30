import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

class MockStdout extends Mock implements Stdout {}

class MockStdin extends Mock implements Stdin {}

void main() {
  group('Logger', () {
    late Stdout stdout;
    late Stdin stdin;

    setUp(() {
      stdout = MockStdout();
      stdin = MockStdin();
    });

    group('.write', () {
      test('writes to stdout', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().write(message);
            verify(() => stdout.write(message)).called(1);
          },
          stdout: () => stdout,
        );
      });
    });

    group('.info', () {
      test('writes line to stdout', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().info(message);
            verify(() => stdout.writeln(message)).called(1);
          },
          stdout: () => stdout,
        );
      });
    });

    group('.delayed', () {
      test('does not write to stdout', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().delayed(message);
            verifyNever(() => stdout.writeln(message));
          },
          stdout: () => stdout,
        );
      });
    });

    group('.flush', () {
      test('writes to stdout', () {
        StdioOverrides.runZoned(
          () {
            const messages = ['test', 'message', '!'];
            final logger = Logger();
            for (final message in messages) {
              logger.delayed(message);
            }
            verifyNever(() => stdout.writeln(any()));

            logger.flush();

            for (final message in messages) {
              verify(() => stdout.writeln(message)).called(1);
            }
          },
          stdout: () => stdout,
        );
      });
    });

    group('.err', () {
      test('writes line to stdout', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().err(message);
            verify(() => stdout.writeln(lightRed.wrap(message))).called(1);
          },
          stdout: () => stdout,
        );
      });
    });

    group('.alert', () {
      test('writes line to stdout', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().alert(message);
            verify(
              () => stdout.writeln(lightCyan.wrap(styleBold.wrap(message))),
            ).called(1);
          },
          stdout: () => stdout,
        );
      });
    });

    group('.detail', () {
      test('writes line to stdout', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().detail(message);
            verify(() => stdout.writeln(darkGray.wrap(message))).called(1);
          },
          stdout: () => stdout,
        );
      });
    });

    group('.warn', () {
      test('writes line to stdout', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().warn(message);
            verify(
              () {
                stdout.writeln(yellow.wrap(styleBold.wrap('[WARN] $message')));
              },
            ).called(1);
          },
          stdout: () => stdout,
        );
      });

      test('writes line to stdout with custom tag', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().warn(message, tag: '🚨');
            verify(
              () {
                stdout.writeln(yellow.wrap(styleBold.wrap('[🚨] $message')));
              },
            ).called(1);
          },
          stdout: () => stdout,
        );
      });
    });

    group('.success', () {
      test('writes line to stdout', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().success(message);
            verify(() => stdout.writeln(lightGreen.wrap(message))).called(1);
          },
          stdout: () => stdout,
        );
      });
    });

    group('.prompt', () {
      test('writes line to stdout and reads line from stdin', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            const response = 'test response';
            const prompt = '$message ';
            final promptWithResponse =
                '''\x1b[A\u001B[2K$message ${styleDim.wrap(lightCyan.wrap(response))}''';
            when(() => stdin.readLineSync()).thenReturn(response);
            final actual = Logger().prompt(message);
            expect(actual, equals(response));
            verify(() => stdout.write(prompt)).called(1);
            verify(() => stdout.writeln(promptWithResponse)).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('writes line to stdout and reads line from stdin with default', () {
        StdioOverrides.runZoned(
          () {
            const defaultValue = 'Dash';
            const message = 'test message';
            const response = 'test response';
            final prompt = '$message ${darkGray.wrap('($defaultValue)')} ';
            final promptWithResponse =
                '''\x1b[A\u001B[2K$prompt${styleDim.wrap(lightCyan.wrap(response))}''';
            when(() => stdin.readLineSync()).thenReturn(response);
            final actual = Logger().prompt(message, defaultValue: defaultValue);
            expect(actual, equals(response));
            verify(() => stdout.write(prompt)).called(1);
            verify(() => stdout.writeln(promptWithResponse)).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('writes line to stdout and reads line from stdin hidden', () {
        StdioOverrides.runZoned(
          () {
            const defaultValue = 'Dash';
            const message = 'test message';
            const response = 'test response';
            final prompt = '$message ${darkGray.wrap('($defaultValue)')} ';
            final promptWithResponse =
                '''\x1b[A\u001B[2K$prompt${styleDim.wrap(lightCyan.wrap('******'))}''';
            final bytes = [
              116,
              101,
              115,
              116,
              32,
              127,
              32,
              114,
              101,
              115,
              112,
              111,
              110,
              115,
              101,
              13,
            ];
            when(() => stdin.readByteSync()).thenAnswer(
              (_) => bytes.removeAt(0),
            );
            final actual = Logger().prompt(
              message,
              defaultValue: defaultValue,
              hidden: true,
            );
            expect(actual, equals(response));
            verify(() => stdout.write(prompt)).called(1);
            verify(() => stdout.writeln(promptWithResponse)).called(1);
            verify(() => stdout.writeln()).called(1);
            verifyNever(() => stdout.write(any()));
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('writes multi line to stdout and resets after response', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message\nwith more\nlines';
            final lines = message.split('\n').length - 1;
            const response = 'test response';
            const prompt = '$message ';
            final promptWithResponse =
                '''\x1b[A\u001B[2K\u001B[${lines}A$message ${styleDim.wrap(lightCyan.wrap(response))}''';
            when(() => stdin.readLineSync()).thenReturn(response);
            final actual = Logger().prompt(message);
            expect(actual, equals(response));
            verify(() => stdout.write(prompt)).called(1);
            verify(() => stdout.writeln(promptWithResponse)).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });
    });

    group('.confirm', () {
      test('writes line to stdout and reads line from stdin (default no)', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            final prompt = 'test message ${darkGray.wrap('(y/N)')} ';
            final promptWithResponse =
                '''\x1b[A\u001B[2K$prompt${styleDim.wrap(lightCyan.wrap('No'))}''';
            when(() => stdin.readLineSync()).thenReturn('');
            final actual = Logger().confirm(message);
            expect(actual, isFalse);
            verify(() => stdout.write(prompt)).called(1);
            verify(() => stdout.writeln(promptWithResponse)).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('writes line to stdout and reads line from stdin (default yes)', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            final prompt = 'test message ${darkGray.wrap('(Y/n)')} ';
            final promptWithResponse =
                '''\x1b[A\u001B[2K$prompt${styleDim.wrap(lightCyan.wrap('Yes'))}''';
            when(() => stdin.readLineSync()).thenReturn('y');
            final actual = Logger().confirm(message, defaultValue: true);
            expect(actual, isTrue);
            verify(() => stdout.write(prompt)).called(1);
            verify(() => stdout.writeln(promptWithResponse)).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('handles all versions of yes correctly', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            final prompt = 'test message ${darkGray.wrap('(y/N)')} ';
            const yesWords = ['y', 'Y', 'Yes', 'yes', 'yeah', 'yea', 'yup'];
            for (final word in yesWords) {
              final promptWithResponse =
                  '''\x1b[A\u001B[2K$prompt${styleDim.wrap(lightCyan.wrap('Yes'))}''';
              when(() => stdin.readLineSync()).thenReturn(word);
              final actual = Logger().confirm(message);
              expect(actual, isTrue);
              verify(() => stdout.write(prompt)).called(1);
              verify(() => stdout.writeln(promptWithResponse)).called(1);
            }
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('handles all versions of no correctly', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            final prompt = 'test message ${darkGray.wrap('(y/N)')} ';
            const noWords = ['n', 'N', 'No', 'no', 'nope', 'Nope', 'nopE'];
            for (final word in noWords) {
              final promptWithResponse =
                  '''\x1b[A\u001B[2K$prompt${styleDim.wrap(lightCyan.wrap('No'))}''';
              when(() => stdin.readLineSync()).thenReturn(word);
              final actual = Logger().confirm(message);
              expect(actual, isFalse);
              verify(() => stdout.write(prompt)).called(1);
              verify(() => stdout.writeln(promptWithResponse)).called(1);
            }
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('returns default when response is neither yes/no (default no)', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            final prompt = 'test message ${darkGray.wrap('(y/N)')} ';
            final promptWithResponse =
                '''\x1b[A\u001B[2K$prompt${styleDim.wrap(lightCyan.wrap('No'))}''';
            when(() => stdin.readLineSync()).thenReturn('maybe');
            final actual = Logger().confirm(message);
            expect(actual, isFalse);
            verify(() => stdout.write(prompt)).called(1);
            verify(() => stdout.writeln(promptWithResponse)).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('returns default when response is neither yes/no (default yes)', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            final prompt = 'test message ${darkGray.wrap('(Y/n)')} ';
            final promptWithResponse =
                '''\x1b[A\u001B[2K$prompt${styleDim.wrap(lightCyan.wrap('Yes'))}''';
            when(() => stdin.readLineSync()).thenReturn('maybe');
            final actual = Logger().confirm(message, defaultValue: true);
            expect(actual, isTrue);
            verify(() => stdout.write(prompt)).called(1);
            verify(() => stdout.writeln(promptWithResponse)).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });
    });

    group('.progress', () {
      test('writes lines to stdout', () async {
        await StdioOverrides.runZoned(
          () async {
            const message = 'test message';
            final done = Logger().progress(message);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            done.complete();
            verify(
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (message.length + 4)}⠙')} $message...''',
                );
              },
            ).called(1);
            verify(
              () {
                stdout.write(
                  '''\b${'\b' * (message.length + 4)}\u001b[2K${lightGreen.wrap('✓')} $message ${darkGray.wrap('(0.1s)')}\n''',
                );
              },
            ).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });
    });

    group('.pickOne', () {
      test(
          'enter selects the initial value '
          'when defaultValue is not specified.', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'a';
            when(() => stdin.readByteSync()).thenReturn(10);
            final actual = Logger().pickOne(message, choices: ['a', 'b', 'c']);
            expect(actual, equals(expected));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')} ${lightCyan.wrap('a')}'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ b'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('enter selects the default value when specified.', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'b';
            when(() => stdin.readByteSync()).thenReturn(10);
            final actual = Logger().pickOne(
              message,
              choices: ['a', 'b', 'c'],
              defaultValue: 'b',
            );
            expect(actual, equals(expected));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')} ${lightCyan.wrap('b')}'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('down arrow selects next index', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'b';
            final bytes = [27, 91, 66, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().pickOne(message, choices: ['a', 'b', 'c']);
            expect(actual, equals(expected));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')} ${lightCyan.wrap('a')}'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ b'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')} ${lightCyan.wrap('b')}'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('up arrow selects previous index', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'a';
            final bytes = [27, 91, 65, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().pickOne(
              message,
              choices: ['a', 'b', 'c'],
              defaultValue: 'b',
            );
            expect(actual, equals(expected));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')} ${lightCyan.wrap('b')}'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')} ${lightCyan.wrap('a')}'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ b'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('up arrow wraps to end', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'c';
            final bytes = [27, 91, 65, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().pickOne(
              message,
              choices: ['a', 'b', 'c'],
            );
            expect(actual, equals(expected));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')} ${lightCyan.wrap('a')}'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ b'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ a'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ b'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')} ${lightCyan.wrap('c')}'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('down arrow wraps to beginning', () {
        StdioOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'a';
            final bytes = [27, 91, 66, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().pickOne(
              message,
              choices: ['a', 'b', 'c'],
              defaultValue: 'c',
            );
            expect(actual, equals(expected));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ a'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ b'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')} ${lightCyan.wrap('c')}'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')} ${lightCyan.wrap('a')}'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ b'),
              () => stdout.write(green.wrap(' ')),
              () => stdout.write(' ◯ c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });
    });
  });
}
