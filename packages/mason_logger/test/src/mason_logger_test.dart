import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mason_logger/src/io.dart';
import 'package:mason_logger/src/mason_logger.dart';
import 'package:mason_logger/src/terminal_overrides.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockStdout extends Mock implements Stdout {}

class _MockStdin extends Mock implements Stdin {}

// While mocktail records a verification, every call on a mock returns null.
// A `wrap()` in an expectation reads `supportsAnsiEscapes` from the stdout or
// stderr mock, gets null and throws, and mocktail then verifies that getter
// instead of the write. These helpers read whether ANSI output is enabled
// first and keep it fixed while mocktail records the expectations.
VerificationResult _verify<T>(T Function() call) =>
    overrideAnsiOutput(ansiOutputEnabled, () => verify(call));

void _verifyNever<T>(T Function() call) =>
    overrideAnsiOutput(ansiOutputEnabled, () => verifyNever(call));

List<VerificationResult> _verifyInOrder<T>(List<T Function()> calls) =>
    overrideAnsiOutput(ansiOutputEnabled, () => verifyInOrder(calls));

void main() {
  group('Logger', () {
    late Stdout stdout;
    late Stdin stdin;
    late Stdout stderr;

    Stdout mockStdout() => stdout;
    Stdout mockStderr() => stderr;

    setUp(() {
      stdout = _MockStdout();
      stdin = _MockStdin();
      stderr = _MockStdout();

      when(() => stdout.supportsAnsiEscapes).thenReturn(true);
      when(() => stderr.supportsAnsiEscapes).thenReturn(true);
      when(() => stdout.hasTerminal).thenReturn(true);
      when(() => stdout.terminalColumns).thenReturn(80);
    });

    // Mocks both stdout and stderr, so whether ANSI output is enabled only
    // depends on the mocks, not on the terminal the tests run in.
    T runWithMocks<T>(
      T Function() body, {
      Stdout Function()? stdout,
      Stdin Function()? stdin,
      Stdout Function()? stderr,
    }) {
      return IOOverrides.runZoned(
        body,
        stdout: stdout ?? mockStdout,
        stdin: stdin,
        stderr: stderr ?? mockStderr,
      );
    }

    group('theme', () {
      test('can be overridden at the logger level', () {
        final theme = LogTheme(info: (message) => '[message]: $message');
        runWithMocks(() {
          const message = 'test message';
          Logger(theme: theme).info(message);
          verify(() => stdout.writeln('[message]: $message')).called(1);
        }, stdout: () => stdout);
      });

      test('can be overridden at the method level', () {
        String? style(String? message) => '[message]: $message';
        runWithMocks(() {
          const message = 'test message';
          Logger().info(message, style: style);
          verify(() => stdout.writeln('[message]: $message')).called(1);
        }, stdout: () => stdout);
      });

      test('is ignored when a method override is used.', () {
        final theme = LogTheme(info: (message) => '[message]: $message');
        String? style(String? message) => '[info]: $message';
        runWithMocks(() {
          const message = 'test message';
          Logger(theme: theme).info(message, style: style);
          verify(() => stdout.writeln('[info]: $message')).called(1);
          Logger(theme: theme).info(message);
          verify(() => stdout.writeln('[message]: $message')).called(1);
        }, stdout: () => stdout);
      });
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
        runWithMocks(() {
          const message = 'test message';
          Logger().write(message);
          verify(() => stdout.write(message)).called(1);
        }, stdout: () => stdout);
      });
    });

    group('.info', () {
      test('writes line to stdout', () {
        runWithMocks(() {
          const message = 'test message';
          Logger().info(message);
          verify(() => stdout.writeln(message)).called(1);
        }, stdout: () => stdout);
      });

      test('does not write to stdout when Level > info', () {
        runWithMocks(() {
          const message = 'test message';
          Logger(level: Level.critical).info(message);
          verifyNever(() => stdout.writeln(contains(message)));
        }, stdout: () => stdout);
      });
    });

    group('.delayed', () {
      test('does not write to stdout', () {
        runWithMocks(() {
          const message = 'test message';
          Logger().delayed(message);
          verifyNever(() => stdout.writeln(message));
        }, stdout: () => stdout);
      });
    });

    group('.flush', () {
      test('writes to stdout', () {
        runWithMocks(() {
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
        }, stdout: () => stdout);
      });
    });

    group('.err', () {
      test('writes line to stderr', () {
        runWithMocks(() {
          const message = 'test message';
          Logger().err(message);
          final expected = lightRed.wrap(message);
          verify(() => stderr.writeln(expected)).called(1);
        }, stderr: () => stderr);
      });

      test('does not write to stderr when Level > error', () {
        runWithMocks(() {
          const message = 'test message';
          Logger(level: Level.critical).err(message);
          final expected = lightRed.wrap(message);
          verifyNever(() => stderr.writeln(expected));
        }, stderr: () => stderr);
      });
    });

    group('.alert', () {
      test('writes line to stderr', () {
        runWithMocks(() {
          const message = 'test message';
          Logger().alert(message);
          final expected = backgroundRed.wrap(
            styleBold.wrap(white.wrap(message)),
          );
          verify(() => stderr.writeln(expected)).called(1);
        }, stderr: () => stderr);
      });

      test('does not write to stderr when Level > critical', () {
        runWithMocks(() {
          const message = 'test message';
          Logger(level: Level.quiet).alert(message);
          final expected = backgroundRed.wrap(
            styleBold.wrap(white.wrap(message)),
          );
          verifyNever(() => stderr.writeln(expected));
        }, stderr: () => stderr);
      });
    });

    group('.detail', () {
      test('writes line to stdout', () {
        runWithMocks(() {
          const message = 'test message';
          Logger(level: Level.debug).detail(message);
          _verify(() => stdout.writeln(darkGray.wrap(message))).called(1);
        }, stdout: () => stdout);
      });

      test('does not write to stdout when Level > debug', () {
        runWithMocks(() {
          const message = 'test message';
          Logger().detail(message);
          _verifyNever(() => stdout.writeln(darkGray.wrap(message)));
        }, stdout: () => stdout);
      });
    });

    group('.warn', () {
      test('writes line to stderr', () {
        runWithMocks(() {
          const message = 'test message';
          Logger().warn(message);
          final expected = yellow.wrap(styleBold.wrap('[WARN] $message'));
          verify(() => stderr.writeln(expected)).called(1);
        }, stderr: () => stderr);
      });

      test('writes line to stderr with custom tag', () {
        runWithMocks(() {
          const message = 'test message';
          Logger().warn(message, tag: '🚨');
          final expected = yellow.wrap(styleBold.wrap('[🚨] $message'));
          verify(() => stderr.writeln(expected)).called(1);
        }, stderr: () => stderr);
      });

      test('writes line to stderr with empty tag', () {
        runWithMocks(() {
          const message = 'test message';
          Logger().warn(message, tag: '');
          final expected = yellow.wrap(styleBold.wrap(message));
          verify(() => stderr.writeln(expected)).called(1);
        }, stderr: () => stderr);
      });

      test('does not write to stderr when Level > warning', () {
        runWithMocks(() {
          const message = 'test message';
          Logger(level: Level.error).warn(message);
          final expected = yellow.wrap(styleBold.wrap('[WARN] $message'));
          verifyNever(() => stderr.writeln(expected));
        }, stderr: () => stderr);
      });
    });

    group('.success', () {
      test('writes line to stdout', () {
        runWithMocks(() {
          const message = 'test message';
          Logger().success(message);
          _verify(() => stdout.writeln(lightGreen.wrap(message))).called(1);
        }, stdout: () => stdout);
      });

      test('does not write to stdout when Level > info', () {
        runWithMocks(() {
          const message = 'test message';
          Logger(level: Level.warning).success(message);
          _verifyNever(() => stdout.writeln(lightGreen.wrap(message)));
        }, stdout: () => stdout);
      });
    });

    group('.prompt', () {
      test('throws NoTerminalAttachedError when no terminal is attached', () {
        when(() => stdout.hasTerminal).thenReturn(false);
        runWithMocks(
          () {
            const message = 'test message';
            const prompt = '$message ';
            expect(
              () => Logger().prompt(message),
              throwsA(isA<NoTerminalAttachedError>()),
            );
            verify(() => stdout.write(prompt)).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('writes line to stdout and reads line from stdin', () {
        runWithMocks(
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
        runWithMocks(
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
        runWithMocks(
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
            when(
              () => stdin.readByteSync(),
            ).thenAnswer((_) => bytes.removeAt(0));
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
        runWithMocks(
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
      test('throws NoTerminalAttachedError when no terminal is attached', () {
        when(() => stdout.hasTerminal).thenReturn(false);
        runWithMocks(
          () {
            const message = 'test message';
            final prompt = 'test message ${darkGray.wrap('(y/N)')} ';
            expect(
              () => Logger().confirm(message),
              throwsA(isA<NoTerminalAttachedError>()),
            );
            verify(() => stdout.write(prompt)).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('writes line to stdout and reads line from stdin (default no)', () {
        runWithMocks(
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
        runWithMocks(
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
        runWithMocks(
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
        runWithMocks(
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

      test('handles multi-line messages correctly', () {
        runWithMocks(
          () {
            const message = 'This is a multi-line\n\nmessage.';
            final prompt =
                'This is a multi-line\n\nmessage. ${darkGray.wrap('(y/N)')} ';
            final promptWithResponse =
                '''\x1b[A\u001B[2K\u001B[2A$prompt${styleDim.wrap(lightCyan.wrap('Yes'))}''';
            when(() => stdin.readLineSync()).thenReturn('y');
            final actual = Logger().confirm(message);
            expect(actual, isTrue);
            verify(() => stdout.write(prompt)).called(1);
            verify(() => stdout.writeln(promptWithResponse)).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('returns default when response is neither yes/no (default no)', () {
        runWithMocks(
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
        runWithMocks(
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

      test('returns default when a utf8 decoding error occurs', () {
        runWithMocks(
          () {
            const message = 'test message';
            final prompt = 'test message ${darkGray.wrap('(y/N)')} ';
            final promptWithResponse =
                '''\x1b[A\u001B[2K$prompt${styleDim.wrap(lightCyan.wrap('No'))}''';
            when(
              () => stdin.readLineSync(),
            ).thenThrow(const FormatException('Missing extension byte'));
            final actual = Logger().confirm(message);
            expect(actual, isFalse);
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
        await runWithMocks(
          () async {
            const message = 'test message';
            final done = Logger().progress(message);
            await Future<void>.delayed(const Duration(milliseconds: 300));
            done.complete();
            _verifyInOrder([
              () => stdout.write(
                any(
                  that: startsWith(
                    '\x1b[?7l\u001b[2K\r${lightGreen.wrap('⠙')} $message... ',
                  ),
                ),
              ),
              () => stdout.write(
                any(
                  that: startsWith(
                    '\x1b[?7l\u001b[2K\r${lightGreen.wrap('⠹')} $message... ',
                  ),
                ),
              ),
              () => stdout.write(
                '\x1b[?7h\u001b[2K\r${lightGreen.wrap('✓')} $message '
                '${darkGray.wrap('(0.3s)')}\n',
              ),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });
    });

    group('.chooseAny', () {
      test('throws NoTerminalAttachedError when no terminal is attached', () {
        when(() => stdout.hasTerminal).thenReturn(false);
        runWithMocks(
          () {
            expect(
              () =>
                  Logger().chooseAny('test message', choices: ['a', 'b', 'c']),
              throwsA(isA<NoTerminalAttachedError>()),
            );
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('exits when control+c is pressed', () {
        final exitCalls = <int>[];
        try {
          TerminalOverrides.runZoned(
            () => runWithMocks(
              () =>
                  Logger().chooseAny('test message', choices: ['a', 'b', 'c']),
              stdout: () => stdout,
              stdin: () => stdin,
            ),
            readKey: () => KeyStroke.control(ControlCharacter.ctrlC),
            exit: (code) {
              exitCalls.add(code);
              throw Exception('exit');
            },
          );
          fail('should have called exit');
        } catch (_) {
          expect(exitCalls, equals([130]));
        }
      });

      test('enter/return selects the nothing '
          'when defaultValues is not specified.', () {
        final keyStrokes = [KeyStroke.control(ControlCharacter.ctrlM)];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              final actual = Logger().chooseAny(
                message,
                choices: ['a', 'b', 'c'],
              );
              expect(actual, isEmpty);
              _verifyInOrder([
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
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('enter/return selects the default values when specified.', () {
        final keyStrokes = [KeyStroke.control(ControlCharacter.ctrlM)];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = ['b', 'c'];
              final actual = Logger().chooseAny(
                message,
                choices: ['a', 'b', 'c'],
                defaultValues: ['b', 'c'],
              );
              expect(actual, equals(expected));
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('a')}'),
                () => stdout.write(' '),
                () => stdout.write(' ${lightCyan.wrap('◉')}  b'),
                () => stdout.write(' '),
                () => stdout.write(' ${lightCyan.wrap('◉')}  c'),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('space selects/deselects the values.', () {
        final keyStrokes = [
          KeyStroke.char(' '),
          KeyStroke.char(' '),
          KeyStroke.control(ControlCharacter.arrowDown),
          KeyStroke.char(' '),
          KeyStroke.control(ControlCharacter.arrowDown),
          KeyStroke.char(' '),
          KeyStroke.control(ControlCharacter.ctrlM),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = ['b', 'c'];
              final actual = Logger().chooseAny(
                message,
                choices: ['a', 'b', 'c'],
              );
              expect(actual, equals(expected));
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('a')}'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('a')}'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' ◯  a'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('b')}'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(' '),
                () => stdout.write(' ${lightCyan.wrap('◉')}  b'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('c')}'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(' '),
                () => stdout.write(' ${lightCyan.wrap('◉')}  b'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('c')}',
                ),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('down arrow selects next index', () {
        final keyStrokes = [
          KeyStroke.control(ControlCharacter.arrowDown),
          KeyStroke.control(ControlCharacter.ctrlM),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              final actual = Logger().chooseAny(
                message,
                choices: ['a', 'b', 'c'],
              );
              expect(actual, equals(isEmpty));
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('a')}'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('b')}'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('redraws in place using relative cursor moves', () {
        final keyStrokes = [
          KeyStroke.control(ControlCharacter.arrowDown),
          KeyStroke.control(ControlCharacter.ctrlM),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              Logger().chooseAny(message, choices: ['a', 'b', 'c']);
              verifyInOrder([
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[3A'),
                () => stdout.write('\r'),
                () => stdout.write('\x1b[J'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
              ]);
              verifyNever(() => stdout.write('\x1b7'));
              verifyNever(() => stdout.write('\x1b8'));
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('j selects next index', () {
        final keyStrokes = [
          KeyStroke.char('j'),
          KeyStroke.control(ControlCharacter.ctrlM),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              final actual = Logger().chooseAny(
                message,
                choices: ['a', 'b', 'c'],
              );
              expect(actual, equals(isEmpty));
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('a')}'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('b')}'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('up arrow wraps to end', () {
        final keyStrokes = [
          KeyStroke.control(ControlCharacter.arrowUp),
          KeyStroke.control(ControlCharacter.ctrlM),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              final actual = Logger().chooseAny(
                message,
                choices: ['a', 'b', 'c'],
              );
              expect(actual, isEmpty);
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('a')}'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
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
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('k wraps to end', () {
        final keyStrokes = [
          KeyStroke.char('k'),
          KeyStroke.control(ControlCharacter.ctrlM),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              final actual = Logger().chooseAny(
                message,
                choices: ['a', 'b', 'c'],
              );
              expect(actual, isEmpty);
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('a')}'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
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
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('down arrow wraps to beginning', () {
        final keyStrokes = [
          KeyStroke.control(ControlCharacter.arrowDown),
          KeyStroke.control(ControlCharacter.arrowDown),
          KeyStroke.control(ControlCharacter.arrowDown),
          KeyStroke.control(ControlCharacter.ctrlM),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              final actual = Logger().chooseAny(
                message,
                choices: ['a', 'b', 'c'],
              );
              expect(actual, isEmpty);
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('a')}'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('b')}'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(' ◯  ${lightCyan.wrap('c')}'),
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
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('converts choices to a preferred display', () {
        final keyStrokes = [KeyStroke.control(ControlCharacter.ctrlM)];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
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
              _verifyInOrder([
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
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('converts results to a preferred display', () {
        final keyStrokes = [KeyStroke.control(ControlCharacter.ctrlM)];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = ['a', 'c'];
              final actual = Logger().chooseAny<String>(
                message,
                choices: ['a', 'b', 'c'],
                defaultValues: ['a', 'c'],
                display: (data) => 'Key: $data',
              );
              expect(actual, equals(expected));
              _verifyInOrder([
                () => stdout.write('\x1b[3A'),
                () => stdout.write('\r'),
                () => stdout.write('\x1b[J'),
                () => stdout.write('$message '),
                () => stdout.writeln(
                  styleDim.wrap(lightCyan.wrap('[Key: a, Key: c]')),
                ),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });
    });

    group('.chooseOne', () {
      test('throws NoTerminalAttachedError when no terminal is attached', () {
        when(() => stdout.hasTerminal).thenReturn(false);
        runWithMocks(
          () {
            expect(
              () =>
                  Logger().chooseOne('test message', choices: ['a', 'b', 'c']),
              throwsA(isA<NoTerminalAttachedError>()),
            );
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('exits when control+c is pressed', () {
        final exitCalls = <int>[];
        try {
          TerminalOverrides.runZoned(
            () => runWithMocks(
              () =>
                  Logger().chooseOne('test message', choices: ['a', 'b', 'c']),
              stdout: () => stdout,
              stdin: () => stdin,
            ),
            readKey: () => KeyStroke.control(ControlCharacter.ctrlC),
            exit: (code) {
              exitCalls.add(code);
              throw Exception('exit');
            },
          );
          fail('should have called exit');
        } catch (_) {
          expect(exitCalls, equals([130]));
        }
      });

      test('enter selects the initial value '
          'when defaultValue is not specified.', () {
        final keyStrokes = [KeyStroke.control(ControlCharacter.ctrlM)];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = 'a';
              final actual = Logger().chooseOne(
                message,
                choices: ['a', 'b', 'c'],
              );
              expect(actual, equals(expected));
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('enter selects the default value when specified.', () {
        final keyStrokes = [KeyStroke.control(ControlCharacter.ctrlM)];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = 'b';
              final actual = Logger().chooseOne(
                message,
                choices: ['a', 'b', 'c'],
                defaultValue: 'b',
              );
              expect(actual, equals(expected));
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('space selects the default value when specified.', () {
        final keyStrokes = [KeyStroke.char(' ')];
        TerminalOverrides.runZoned(
          () => runWithMocks(
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
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('down arrow selects next index', () {
        final keyStrokes = [
          KeyStroke.control(ControlCharacter.arrowDown),
          KeyStroke.control(ControlCharacter.ctrlJ),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = 'b';
              final actual = Logger().chooseOne(
                message,
                choices: ['a', 'b', 'c'],
              );
              expect(actual, equals(expected));
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('redraws in place using relative cursor moves', () {
        final keyStrokes = [
          KeyStroke.control(ControlCharacter.arrowDown),
          KeyStroke.control(ControlCharacter.ctrlJ),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              Logger().chooseOne(message, choices: ['a', 'b', 'c']);
              verifyInOrder([
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[3A'),
                () => stdout.write('\r'),
                () => stdout.write('\x1b[J'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
              ]);
              verifyNever(() => stdout.write('\x1b7'));
              verifyNever(() => stdout.write('\x1b8'));
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('up arrow selects previous index', () {
        final keyStrokes = [
          KeyStroke.control(ControlCharacter.arrowUp),
          KeyStroke.control(ControlCharacter.ctrlJ),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = 'a';
              final actual = Logger().chooseOne(
                message,
                choices: ['a', 'b', 'c'],
                defaultValue: 'b',
              );
              expect(actual, equals(expected));
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('up arrow wraps to end', () {
        final keyStrokes = [
          KeyStroke.control(ControlCharacter.arrowUp),
          KeyStroke.control(ControlCharacter.ctrlJ),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = 'c';
              final actual = Logger().chooseOne(
                message,
                choices: ['a', 'b', 'c'],
              );
              expect(actual, equals(expected));
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('c')}',
                ),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('down arrow wraps to beginning', () {
        final keyStrokes = [
          KeyStroke.control(ControlCharacter.arrowDown),
          KeyStroke.control(ControlCharacter.ctrlJ),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = 'a';
              final actual = Logger().chooseOne(
                message,
                choices: ['a', 'b', 'c'],
                defaultValue: 'c',
              );
              expect(actual, equals(expected));
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('c')}',
                ),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('j selects next index', () {
        final keyStrokes = [
          KeyStroke.char('j'),
          KeyStroke.control(ControlCharacter.ctrlJ),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = 'b';
              final actual = Logger().chooseOne(
                message,
                choices: ['a', 'b', 'c'],
              );
              expect(actual, equals(expected));
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('k selects previous index', () {
        final keyStrokes = [
          KeyStroke.char('k'),
          KeyStroke.control(ControlCharacter.ctrlJ),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = 'a';
              final actual = Logger().chooseOne(
                message,
                choices: ['a', 'b', 'c'],
                defaultValue: 'b',
              );
              expect(actual, equals(expected));
              _verifyInOrder([
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(' '),
                () => stdout.write(' ◯  a'),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('b')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
                () => stdout.write('\x1b[?25l'),
                () => stdout.writeln(message),
                () => stdout.write(green.wrap('❯')),
                () => stdout.write(
                  ' ${lightCyan.wrap('◉')}  ${lightCyan.wrap('a')}',
                ),
                () => stdout.write(' '),
                () => stdout.write(' ◯  b'),
                () => stdout.write(' '),
                () => stdout.write(' ◯  c'),
              ]);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('converts choices to a preferred display', () {
        final keyStrokes = [KeyStroke.control(ControlCharacter.ctrlJ)];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = {'key': 'a'};
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
              _verifyInOrder([
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
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });
    });

    group('promptAny', () {
      test('throws NoTerminalAttachedError when no terminal is attached', () {
        when(() => stdout.hasTerminal).thenReturn(false);
        runWithMocks(
          () {
            const message = 'test message';
            expect(
              () => Logger().promptAny(message),
              throwsA(isA<NoTerminalAttachedError>()),
            );
            verify(() => stdout.write('$message ')).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('returns empty list', () {
        final keyStrokes = [KeyStroke.control(ControlCharacter.ctrlJ)];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = <String>[];
              final actual = Logger().promptAny(message);
              expect(actual, equals(expected));
              verify(() => stdout.write('$message ')).called(1);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('returns list with 1 item ([dart])', () {
        final keyStrokes = [
          KeyStroke.char('d'),
          KeyStroke.char('a'),
          KeyStroke.char('r'),
          KeyStroke.char('t'),
          KeyStroke.control(ControlCharacter.ctrlJ),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = <String>['dart'];
              final actual = Logger().promptAny(message);
              expect(actual, equals(expected));
              verify(() => stdout.write('$message ')).called(1);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('returns list with 2 items ([dart, css])', () {
        final keyStrokes = [
          KeyStroke.char('d'),
          KeyStroke.char('a'),
          KeyStroke.char('r'),
          KeyStroke.char('t'),
          KeyStroke.char(','),
          KeyStroke.char('c'),
          KeyStroke.char('s'),
          KeyStroke.char('s'),
          KeyStroke.control(ControlCharacter.ctrlJ),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = ['dart', 'css'];
              final actual = Logger().promptAny(message);
              expect(actual, equals(expected));
              verify(() => stdout.write('$message ')).called(1);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('ignores trailing delimiter', () {
        final keyStrokes = [
          KeyStroke.char('d'),
          KeyStroke.char('a'),
          KeyStroke.char('r'),
          KeyStroke.char('t'),
          KeyStroke.char(','),
          KeyStroke.char('c'),
          KeyStroke.char('s'),
          KeyStroke.char('s'),
          KeyStroke.char(','),
          KeyStroke.control(ControlCharacter.ctrlJ),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = ['dart', 'css'];
              final actual = Logger().promptAny(message);
              expect(actual, equals(expected));
              verify(() => stdout.write('$message ')).called(1);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('ignores other control characters', () {
        final keyStrokes = [
          KeyStroke.char('d'),
          KeyStroke.char('a'),
          KeyStroke.char('r'),
          KeyStroke.char('t'),
          KeyStroke.control(ControlCharacter.ctrlZ),
          KeyStroke.control(ControlCharacter.arrowLeft),
          KeyStroke.control(ControlCharacter.arrowLeft),
          KeyStroke.control(ControlCharacter.arrowRight),
          KeyStroke.char(','),
          KeyStroke.char('c'),
          KeyStroke.char('s'),
          KeyStroke.char('s'),
          KeyStroke.char(','),
          KeyStroke.control(ControlCharacter.ctrlJ),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = ['dart', 'css'];
              final actual = Logger().promptAny(message);
              expect(actual, equals(expected));
              verify(() => stdout.write('$message ')).called(1);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('custom separator (;)', () {
        final keyStrokes = [
          KeyStroke.char('d'),
          KeyStroke.char('a'),
          KeyStroke.char('r'),
          KeyStroke.char('t'),
          KeyStroke.char(';'),
          KeyStroke.char('c'),
          KeyStroke.char('s'),
          KeyStroke.char('s'),
          KeyStroke.control(ControlCharacter.ctrlM),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = ['dart', 'css'];
              final actual = Logger().promptAny(message, separator: ';');
              expect(actual, equals(expected));
              verify(() => stdout.write('$message ')).called(1);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('custom separator (" ")', () {
        final keyStrokes = [
          KeyStroke.char('d'),
          KeyStroke.char('a'),
          KeyStroke.char('r'),
          KeyStroke.char('t'),
          KeyStroke.char(' '),
          KeyStroke.char('c'),
          KeyStroke.char('s'),
          KeyStroke.char('s'),
          KeyStroke.control(ControlCharacter.ctrlJ),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = ['dart', 'css'];
              final actual = Logger().promptAny(message, separator: ' ');
              expect(actual, equals(expected));
              verify(() => stdout.write('$message ')).called(1);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });

      test('backspace deletes delimiter', () {
        final keyStrokes = [
          KeyStroke.char('d'),
          KeyStroke.char('a'),
          KeyStroke.char('r'),
          KeyStroke.char('t'),
          KeyStroke.char(','),
          KeyStroke.char('x'),
          KeyStroke.control(ControlCharacter.delete),
          KeyStroke.control(ControlCharacter.delete),
          KeyStroke.char(','),
          KeyStroke.char('c'),
          KeyStroke.char('s'),
          KeyStroke.char('s'),
          KeyStroke.control(ControlCharacter.ctrlJ),
        ];
        TerminalOverrides.runZoned(
          () => runWithMocks(
            () {
              const message = 'test message';
              const expected = ['dart', 'css'];
              final actual = Logger().promptAny(message);
              expect(actual, equals(expected));
              verify(() => stdout.write('$message ')).called(1);
            },
            stdout: () => stdout,
            stdin: () => stdin,
          ),
          readKey: () => keyStrokes.removeAt(0),
        );
      });
    });
  });
}
