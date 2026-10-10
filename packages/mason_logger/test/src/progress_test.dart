import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockStdout extends Mock implements Stdout {}

// While mocktail records a verification, every call on a mock returns null.
// A `wrap()` in an expectation reads `supportsAnsiEscapes` from the stdout
// mock, gets null and throws, and mocktail then verifies that getter instead
// of the write. This reads whether ANSI output is enabled first and keeps it
// fixed while mocktail records the expectations.
List<VerificationResult> _verifyInOrder<T>(List<T Function()> calls) =>
    overrideAnsiOutput(ansiOutputEnabled, () => verifyInOrder(calls));

void main() {
  group('Progress', () {
    late Stdout stdout;

    setUp(() {
      stdout = _MockStdout();
      when(() => stdout.supportsAnsiEscapes).thenReturn(true);
      when(() => stdout.hasTerminal).thenReturn(true);
      when(() => stdout.terminalColumns).thenReturn(80);
    });

    test('writes ms when elapsed time is less than 0.1s', () async {
      await _runZoned(
        () async {
          const message = 'test message';
          final progress = Logger().progress(message);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          progress.complete();
          verify(
            () => stdout.write(any(that: matches(RegExp(r'\(\d\dms\)')))),
          ).called(1);
        },
        stdout: () => stdout,
        zoneValues: {AnsiCode: true},
      );
    });

    test('truncates message when length exceeds terminal columns', () async {
      await _runZoned(
        () async {
          const message = 'this is a very long message that will be truncated.';
          when(() => stdout.terminalColumns).thenReturn(36);
          final progress = Logger().progress(message);
          await Future<void>.delayed(const Duration(milliseconds: 400));
          progress.complete();
          verifyInOrder([
            () {
              stdout.write(
                any(
                  that: matches(
                    RegExp(r'this is a very long m\.\.\..*\(0.2s\)'),
                  ),
                ),
              );
            },
            () {
              stdout.write(
                any(
                  that: matches(
                    RegExp(r'this is a very long m\.\.\..*\(0.3s\)'),
                  ),
                ),
              );
            },
            () {
              stdout.write(
                any(
                  that: matches(
                    RegExp(
                      r'this is a very long message that will be truncated\..*\(0.4s\)',
                    ),
                  ),
                ),
              );
            },
          ]);
        },
        stdout: () => stdout,
        zoneValues: {AnsiCode: true},
      );
    });

    test('writes full message when stdout does not have a terminal', () async {
      await _runZoned(
        () async {
          const message = 'this is a very long message that will be truncated.';
          when(() => stdout.hasTerminal).thenReturn(false);
          final progress = Logger().progress(message);
          await Future<void>.delayed(const Duration(milliseconds: 400));
          progress.complete();
          verify(() {
            stdout.write(
              any(
                that: matches(
                  RegExp(
                    r'this is a very long message that will be truncated\..*\(0.4s\)',
                  ),
                ),
              ),
            );
          }).called(1);
        },
        stdout: () => stdout,
        zoneValues: {AnsiCode: true},
      );
    });

    test('writes static message when stdioType is not terminal', () async {
      when(() => stdout.hasTerminal).thenReturn(false);
      await _runZoned(
        () async {
          const message = 'test message';
          final done = Logger().progress(message);
          await Future<void>.delayed(const Duration(milliseconds: 400));
          done.complete();
          _verifyInOrder([
            () => stdout.write('${lightGreen.wrap('⠋')} $message...'),
            () {
              stdout.write(
                '''\r${lightGreen.wrap('✓')} $message ${darkGray.wrap('(0.4s)')}\n''',
              );
            },
          ]);
        },
        stdout: () => stdout,
        zoneValues: {AnsiCode: true},
      );
    });

    test(
      'writes static message when stdioType is not terminal w/custom trailing',
      () async {
        const progressOptions = ProgressOptions(trailing: '!!!');
        when(() => stdout.hasTerminal).thenReturn(false);
        await _runZoned(
          () async {
            const message = 'test message';
            final done = Logger(
              progressOptions: progressOptions,
            ).progress(message);
            await Future<void>.delayed(const Duration(milliseconds: 400));
            done.complete();
            _verifyInOrder([
              () => stdout.write('${lightGreen.wrap('⠋')} $message!!!'),
              () {
                stdout.write(
                  '''\r${lightGreen.wrap('✓')} $message ${darkGray.wrap('(0.4s)')}\n''',
                );
              },
            ]);
          },
          stdout: () => stdout,
          zoneValues: {AnsiCode: true},
        );
      },
    );

    test('writes custom progress animation to stdout', () async {
      await _runZoned(
        () async {
          const message = 'test message';
          const progressOptions = ProgressOptions(
            animation: ProgressAnimation(frames: ['+', 'x', '*']),
          );
          final done = Logger().progress(message, options: progressOptions);
          await Future<void>.delayed(const Duration(milliseconds: 400));
          done.complete();
          _verifyInOrder([
            () => stdout.write(
              any(
                that: startsWith(
                  '\x1b[?7l\u001b[2K\r${lightGreen.wrap('x')} $message... ',
                ),
              ),
            ),
            () => stdout.write(
              any(
                that: startsWith(
                  '\x1b[?7l\u001b[2K\r${lightGreen.wrap('*')} $message... ',
                ),
              ),
            ),
            () => stdout.write(
              any(
                that: startsWith(
                  '\x1b[?7l\u001b[2K\r${lightGreen.wrap('+')} $message... ',
                ),
              ),
            ),
            () => stdout.write(
              '\x1b[?7h\u001b[2K\r${lightGreen.wrap('✓')} $message '
              '${darkGray.wrap('(0.4s)')}\n',
            ),
          ]);
        },
        stdout: () => stdout,
        stdin: () => stdin,
        zoneValues: {AnsiCode: true},
      );
    });

    test('writes custom progress interval to stdout', () async {
      await _runZoned(
        () async {
          const message = 'test message';
          const progressOptions = ProgressOptions(
            animation: ProgressAnimation(interval: Duration(milliseconds: 400)),
          );
          final done = Logger().progress(message, options: progressOptions);
          await Future<void>.delayed(const Duration(milliseconds: 400));
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
              '\x1b[?7h\u001b[2K\r${lightGreen.wrap('✓')} $message '
              '${darkGray.wrap('(0.4s)')}\n',
            ),
          ]);
          verifyNever(() => stdout.write(any(that: contains('0.2s'))));
          verifyNever(() => stdout.write(any(that: contains('0.3s'))));
        },
        stdout: () => stdout,
        stdin: () => stdin,
        zoneValues: {AnsiCode: true},
      );
    });

    test('supports empty list of animation frames', () async {
      await _runZoned(
        () async {
          const message = 'test message';
          const progressOptions = ProgressOptions(
            animation: ProgressAnimation(frames: []),
          );
          final done = Logger().progress(message, options: progressOptions);
          await Future<void>.delayed(const Duration(milliseconds: 400));
          done.complete();
          _verifyInOrder([
            () => stdout.write(
              any(that: startsWith('\x1b[?7l\u001b[2K\r$message... ')),
            ),
            () => stdout.write(
              any(that: startsWith('\x1b[?7l\u001b[2K\r$message... ')),
            ),
            () => stdout.write(
              any(that: startsWith('\x1b[?7l\u001b[2K\r$message... ')),
            ),
            () => stdout.write(
              '\x1b[?7h\u001b[2K\r${lightGreen.wrap('✓')} $message '
              '${darkGray.wrap('(0.4s)')}\n',
            ),
          ]);
        },
        stdout: () => stdout,
        stdin: () => stdin,
        zoneValues: {AnsiCode: true},
      );
    });

    test(
      'writes custom progress animation to stdout w/custom trailing',
      () async {
        await _runZoned(
          () async {
            const message = 'test message';
            const progressOptions = ProgressOptions(
              animation: ProgressAnimation(frames: ['+', 'x', '*']),
              trailing: '!!!',
            );
            final done = Logger().progress(message, options: progressOptions);
            await Future<void>.delayed(const Duration(milliseconds: 400));
            done.complete();
            _verifyInOrder([
              () => stdout.write(
                any(
                  that: startsWith(
                    '\x1b[?7l\u001b[2K\r${lightGreen.wrap('x')} $message!!! ',
                  ),
                ),
              ),
              () => stdout.write(
                any(
                  that: startsWith(
                    '\x1b[?7l\u001b[2K\r${lightGreen.wrap('*')} $message!!! ',
                  ),
                ),
              ),
              () => stdout.write(
                any(
                  that: startsWith(
                    '\x1b[?7l\u001b[2K\r${lightGreen.wrap('+')} $message!!! ',
                  ),
                ),
              ),
              () => stdout.write(
                '\x1b[?7h\u001b[2K\r${lightGreen.wrap('✓')} $message '
                '${darkGray.wrap('(0.4s)')}\n',
              ),
            ]);
          },
          stdout: () => stdout,
          stdin: () => stdin,
          zoneValues: {AnsiCode: true},
        );
      },
    );

    group('.complete', () {
      test('writes lines to stdout', () async {
        await _runZoned(
          () async {
            const message = 'test message';
            final progress = Logger().progress(message);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.complete();
            verify(() {
              stdout.write(
                any(that: matches(RegExp(r'⠙.*test message\.\.\..*\(8\dms\)'))),
              );
            }).called(1);
            verify(() {
              stdout.write(
                any(that: matches(RegExp(r'✓.*test message.*\(0.1s\)'))),
              );
            }).called(1);
          },
          stdout: () => stdout,
          zoneValues: {AnsiCode: true},
        );
      });

      test('does not write lines to stdout when Level > info', () async {
        await _runZoned(
          () async {
            const message = 'test message';
            final progress = Logger(level: Level.warning).progress(message);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.complete();
            verifyNever(() => stdout.write(any()));
          },
          stdout: () => stdout,
          zoneValues: {AnsiCode: true},
        );
      });
    });

    group('.update', () {
      test('writes lines to stdout', () async {
        await _runZoned(
          () async {
            const message = 'message';
            const update = 'update';
            final progress = Logger().progress(message);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.update(update);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            verify(() {
              stdout.write(
                any(that: matches(RegExp(r'⠙.*message\.\.\..*\(8\dms\)'))),
              );
            }).called(1);

            verify(() {
              stdout.write(
                any(that: matches(RegExp(r'⠹.*update\.\.\..*\(0\.1s\)'))),
              );
            }).called(1);
          },
          stdout: () => stdout,
          zoneValues: {AnsiCode: true},
        );
      });

      test('does not writes to stdout when Level > info', () async {
        await _runZoned(
          () async {
            const message = 'message';
            const update = 'update';
            final progress = Logger(level: Level.warning).progress(message);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.update(update);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            verifyNever(() => stdout.write(any()));
          },
          stdout: () => stdout,
          zoneValues: {AnsiCode: true},
        );
      });
    });

    group('.fail', () {
      test('writes lines to stdout', () async {
        await _runZoned(
          () async {
            const message = 'test message';
            final progress = Logger().progress(message);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.fail();

            verify(() {
              stdout.write(
                any(that: matches(RegExp(r'⠙.*test message\.\.\..*\(8\dms\)'))),
              );
            }).called(1);

            verify(() {
              stdout.write(
                any(that: matches(RegExp(r'✗.*test message.*\(0\.1s\)'))),
              );
            }).called(1);
          },
          stdout: () => stdout,
          zoneValues: {AnsiCode: true},
        );
      });

      test('does not write to stdout when Level > info', () async {
        await _runZoned(
          () async {
            const message = 'test message';
            final progress = Logger(level: Level.warning).progress(message);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.fail();
            verifyNever(() => stdout.write(any()));
          },
          stdout: () => stdout,
          zoneValues: {AnsiCode: true},
        );
      });
    });

    group('.cancel', () {
      test('writes lines to stdout', () async {
        await _runZoned(
          () async {
            const message = 'test message';
            final progress = Logger().progress(message);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.cancel();
            verify(() {
              stdout.write(
                any(
                  that: matches(
                    RegExp(
                      r'\[2K\u000D\[92m⠙\[0m test message... \[90m\(8\dms\)\[0m',
                    ),
                  ),
                ),
              );
            }).called(1);

            verify(() {
              stdout.write(any(that: matches(RegExp(r'\[2K\u000D'))));
            }).called(1);
          },
          stdout: () => stdout,
          zoneValues: {AnsiCode: true},
        );
      });

      test('does not write to stdout when Level > info', () async {
        await _runZoned(
          () async {
            const message = 'test message';
            final progress = Logger(level: Level.warning).progress(message);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.cancel();
            verifyNever(() => stdout.write(any()));
          },
          stdout: () => stdout,
          zoneValues: {AnsiCode: true},
        );
      });
    });
  });
}

T _runZoned<T>(
  T Function() body, {
  Map<Object?, Object?>? zoneValues,
  Stdin Function()? stdin,
  Stdout Function()? stdout,
}) {
  return runZoned(
    () => IOOverrides.runZoned(body, stdout: stdout, stdin: stdin),
    zoneValues: zoneValues,
  );
}
