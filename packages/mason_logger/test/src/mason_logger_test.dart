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
            const prompt = 'test message';
            const response = 'test response';
            when(() => stdin.readLineSync()).thenReturn(response);
            final actual = Logger().prompt(prompt);
            expect(actual, equals(response));
            verify(() => stdout.write(prompt)).called(1);
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
            done();
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
                  '''${lightGreen.wrap('\b${'\b' * (message.length + 4)}✓')} $message (0.1s)\n''',
                );
              },
            ).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });
    });
  });
}
