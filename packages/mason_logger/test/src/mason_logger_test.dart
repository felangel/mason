import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStdout extends Mock implements Stdout {}

class MockStdin extends Mock implements Stdin {}

void main() {
  group('Logger', () {
    late Stdout stdout;
    late Stdin stdin;
    late Stdout stderr;

    setUp(() {
      stdout = MockStdout();
      stdin = MockStdin();
      stderr = MockStdout();

      when(() => stdout.supportsAnsiEscapes).thenReturn(true);
    });

    group('level', () {
      test('is mutable', () {
        final logger = Logger();
        expect(logger.level, equals(Level.info));
        logger.level = Level.verbose;
        expect(logger.level, equals(Level.verbose));
      });
    });

    group('progressOptions', () {
      test('are set by default', () {
        expect(Logger().progressOptions, equals(const ProgressOptions()));
      });

      test('can be injected via constructor', () {
        const customProgressOptions = ProgressOptions(
          animation: ProgressAnimation(frames: []),
        );
        expect(
          Logger(progressOptions: customProgressOptions).progressOptions,
          equals(customProgressOptions),
        );
      });

      test('are mutable', () {
        final logger = Logger();
        const customProgressOptions = ProgressOptions(
          animation: ProgressAnimation(frames: []),
        );
        expect(logger.progressOptions, equals(const ProgressOptions()));
        logger.progressOptions = customProgressOptions;
        expect(logger.progressOptions, equals(customProgressOptions));
      });
    });

    group('.write', () {
      test('writes to stdout', () {
        IOOverrides.runZoned(
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
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().info(message);
            verify(() => stdout.writeln(message)).called(1);
          },
          stdout: () => stdout,
        );
      });

      test('does not write to stdout when Level > info', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            Logger(level: Level.critical).info(message);
            verifyNever(() => stdout.writeln(contains(message)));
          },
          stdout: () => stdout,
        );
      });
    });

    group('.delayed', () {
      test('does not write to stdout', () {
        IOOverrides.runZoned(
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
        IOOverrides.runZoned(
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
      test('writes line to stderr', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().err(message);
            verify(() => stderr.writeln(lightRed.wrap(message))).called(1);
          },
          stderr: () => stderr,
        );
      });

      test('does not write to stderr when Level > error', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            Logger(level: Level.critical).err(message);
            verifyNever(() => stderr.writeln(lightRed.wrap(message)));
          },
          stderr: () => stderr,
        );
      });
    });

    group('.alert', () {
      test('writes line to stderr', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().alert(message);
            verify(
              () => stderr.writeln(
                backgroundRed.wrap(styleBold.wrap(white.wrap(message))),
              ),
            ).called(1);
          },
          stderr: () => stderr,
        );
      });

      test('does not write to stderr when Level > critical', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            Logger(level: Level.quiet).alert(message);
            verifyNever(
              () => stderr.writeln(
                backgroundRed.wrap(styleBold.wrap(white.wrap(message))),
              ),
            );
          },
          stderr: () => stderr,
        );
      });
    });

    group('.detail', () {
      test('writes line to stdout', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            Logger(level: Level.debug).detail(message);
            verify(() => stdout.writeln(darkGray.wrap(message))).called(1);
          },
          stdout: () => stdout,
        );
      });

      test('does not write to stdout when Level > debug', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().detail(message);
            verifyNever(() => stdout.writeln(darkGray.wrap(message)));
          },
          stdout: () => stdout,
        );
      });
    });

    group('.warn', () {
      test('writes line to stderr', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().warn(message);
            verify(
              () {
                stderr.writeln(yellow.wrap(styleBold.wrap('[WARN] $message')));
              },
            ).called(1);
          },
          stderr: () => stderr,
        );
      });

      test('writes line to stderr with custom tag', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().warn(message, tag: '🚨');
            verify(
              () {
                stderr.writeln(yellow.wrap(styleBold.wrap('[🚨] $message')));
              },
            ).called(1);
          },
          stderr: () => stderr,
        );
      });

      test('does not write to stderr when Level > warning', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            Logger(level: Level.error).warn(message);
            verifyNever(() {
              stderr.writeln(yellow.wrap(styleBold.wrap('[WARN] $message')));
            });
          },
          stderr: () => stderr,
        );
      });
    });

    group('.success', () {
      test('writes line to stdout', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            Logger().success(message);
            verify(() => stdout.writeln(lightGreen.wrap(message))).called(1);
          },
          stdout: () => stdout,
        );
      });

      test('does not write to stdout when Level > info', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            Logger(level: Level.warning).success(message);
            verifyNever(() => stdout.writeln(lightGreen.wrap(message)));
          },
          stdout: () => stdout,
        );
      });
    });

    group('.prompt', () {
      test('writes line to stdout and reads line from stdin', () {
        IOOverrides.runZoned(
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
        IOOverrides.runZoned(
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
        IOOverrides.runZoned(
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
        IOOverrides.runZoned(
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
        IOOverrides.runZoned(
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
        IOOverrides.runZoned(
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
        IOOverrides.runZoned(
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
        IOOverrides.runZoned(
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
        IOOverrides.runZoned(
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
        IOOverrides.runZoned(
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
        when(() => stdout.hasTerminal).thenReturn(true);
        await IOOverrides.runZoned(
          () async {
            const time = '(0.Xs)';
            const message = 'test message';
            final done = Logger().progress(message);
            await Future<void>.delayed(const Duration(milliseconds: 300));
            done.complete();
            verifyInOrder([
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}⠙')} $message... ${darkGray.wrap('(0.1s)')}''',
                );
              },
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}⠹')} $message... ${darkGray.wrap('(0.2s)')}''',
                );
              },
              () {
                stdout.write(
                  '''\b${'\b' * (message.length + 4 + time.length)}\u001b[2K${lightGreen.wrap('✓')} $message ${darkGray.wrap('(0.3s)')}\n''',
                );
              },
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });
    });

    group('.chooseAny', () {
      test(
          'enter selects the nothing '
          'when defaultValues is not specified.', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            when(() => stdin.readByteSync()).thenReturn(10);
            final actual = Logger().chooseAny(
              message,
              choices: ['a', 'b', 'c'],
            );
            expect(actual, isEmpty);
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout.write(' ◯  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('enter selects the default values when specified.', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = ['b', 'c'];
            when(() => stdin.readByteSync()).thenReturn(10);
            final actual = Logger().chooseAny(
              message,
              choices: ['a', 'b', 'c'],
              defaultValues: ['b', 'c'],
            );
            expect(actual, equals(expected));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout.write(' ◯  a'),
              () => stdout.write(' '),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}'),
              () => stdout.write(' '),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('c')}'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('space selected/deselects the values.', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = ['b', 'c'];
            final bytes = [32, 32, 27, 91, 66, 32, 27, 91, 66, 32, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().chooseAny(
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
                  .write(' ${lightCyan.wrap('◯')}  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◯')}  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◯')}  ${lightCyan.wrap('b')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(' '),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}'),
              () => stdout.write(green.wrap('❯')),
              () => stdout.write(' ◯  ${lightCyan.wrap('c')}'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(' '),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('c')}'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('down arrow selects next index', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            final bytes = [27, 91, 66, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().chooseAny(
              message,
              choices: ['a', 'b', 'c'],
            );
            expect(actual, equals(isEmpty));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◯')}  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◯')}  ${lightCyan.wrap('b')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('j selects next index', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            final bytes = [106, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().chooseAny(
              message,
              choices: ['a', 'b', 'c'],
            );
            expect(actual, equals(isEmpty));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◯')}  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◯')}  ${lightCyan.wrap('b')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('up arrow wraps to end', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            final bytes = [27, 91, 65, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().chooseAny(
              message,
              choices: ['a', 'b', 'c'],
            );
            expect(actual, isEmpty);
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout.write(' ◯  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(green.wrap('❯')),
              () => stdout.write(' ◯  ${lightCyan.wrap('c')}'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('k wraps to end', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            final bytes = [107, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().chooseAny(
              message,
              choices: ['a', 'b', 'c'],
            );
            expect(actual, isEmpty);
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout.write(' ◯  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(green.wrap('❯')),
              () => stdout.write(' ◯  ${lightCyan.wrap('c')}'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('down arrow wraps to beginning', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            final bytes = [27, 91, 66, 27, 91, 66, 27, 91, 66, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().chooseAny(
              message,
              choices: ['a', 'b', 'c'],
            );
            expect(actual, isEmpty);
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout.write(' ◯  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout.write(' ◯  ${lightCyan.wrap('b')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(green.wrap('❯')),
              () => stdout.write(' ◯  ${lightCyan.wrap('c')}'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout.write(' ◯  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('converts choices to a preferred display', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            when(() => stdin.readByteSync()).thenReturn(10);
            final actual = Logger().chooseAny<Map<String, String>>(
              message,
              choices: [
                {'key': 'a'},
                {'key': 'b'},
                {'key': 'c'},
              ],
              display: (data) => 'Key: ${data['key']}',
            );
            expect(actual, isEmpty);
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout.write(' ◯  ${lightCyan.wrap('Key: a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  Key: b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  Key: c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });
    });

    group('.chooseOne', () {
      test(
          'enter selects the initial value '
          'when defaultValue is not specified.', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'a';
            when(() => stdin.readByteSync()).thenReturn(10);
            final actual = Logger().chooseOne(
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
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('enter selects the default value when specified.', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'b';
            when(() => stdin.readByteSync()).thenReturn(10);
            final actual = Logger().chooseOne(
              message,
              choices: ['a', 'b', 'c'],
              defaultValue: 'b',
            );
            expect(actual, equals(expected));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('space selects the default value when specified.', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'b';
            when(() => stdin.readByteSync()).thenReturn(32);
            final actual = Logger().chooseOne(
              message,
              choices: ['a', 'b', 'c'],
              defaultValue: 'b',
            );
            expect(actual, equals(expected));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('down arrow selects next index', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'b';
            final bytes = [27, 91, 66, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().chooseOne(
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
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('up arrow selects previous index', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'a';
            final bytes = [27, 91, 65, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().chooseOne(
              message,
              choices: ['a', 'b', 'c'],
              defaultValue: 'b',
            );
            expect(actual, equals(expected));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('up arrow wraps to end', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'c';
            final bytes = [27, 91, 65, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().chooseOne(
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
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('c')}'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('down arrow wraps to beginning', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'a';
            final bytes = [27, 91, 66, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().chooseOne(
              message,
              choices: ['a', 'b', 'c'],
              defaultValue: 'c',
            );
            expect(actual, equals(expected));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('c')}'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('j selects next index', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'b';
            final bytes = [106, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().chooseOne(
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
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('k selects previous index', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = 'a';
            final bytes = [107, 10];
            when(() => stdin.readByteSync()).thenAnswer((_) {
              return bytes.removeAt(0);
            });
            final actual = Logger().chooseOne(
              message,
              choices: ['a', 'b', 'c'],
              defaultValue: 'b',
            );
            expect(actual, equals(expected));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(' '),
              () => stdout.write(' ◯  a'),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout
                  .write(' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('converts choices to a preferred display', () {
        IOOverrides.runZoned(
          () {
            const message = 'test message';
            const expected = {'key': 'a'};
            when(() => stdin.readByteSync()).thenReturn(10);
            final actual = Logger().chooseOne<Map<String, String>>(
              message,
              choices: [
                {'key': 'a'},
                {'key': 'b'},
                {'key': 'c'},
              ],
              display: (data) => 'Key: ${data['key']}',
            );
            expect(actual, equals(expected));
            verifyInOrder([
              () => stdout.write('\x1b7'),
              () => stdout.write('\x1b[?25l'),
              () => stdout.writeln(message),
              () => stdout.write(green.wrap('❯')),
              () => stdout.write(
                    ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('Key: a')}',
                  ),
              () => stdout.write(' '),
              () => stdout.write(' ◯  Key: b'),
              () => stdout.write(' '),
              () => stdout.write(' ◯  Key: c'),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });
    });
  });
}
