import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

class MockStdout extends Mock implements Stdout {}

class MockStdin extends Mock implements Stdin {}

void main() {
  group('Progress', () {
    late Stdout stdout;
    late Stdin stdin;
    late LogLevel level;

    setUp(() {
      stdout = MockStdout();
      stdin = MockStdin();
      level = LogLevel.info;
    });

    group('.complete', () {
      test('writes lines to stdout', () async {
        await StdioOverrides.runZoned(
          () async {
            const time = '(0.1s)';
            const message = 'test message';
            final progress = Progress(message, stdout, level);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.complete();
            verify(
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}⠙')} $message... ${darkGray.wrap(time)}''',
                );
              },
            ).called(1);
            verify(
              () {
                stdout.write(
                  '''\b${'\b' * (message.length + 4 + time.length)}\u001b[2K${lightGreen.wrap('✓')} $message ${darkGray.wrap(time)}\n''',
                );
              },
            ).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('does not write lines to stdout when LogLevel > info', () async {
        await StdioOverrides.runZoned(
          () async {
            const time = '(0.1s)';
            const message = 'test message';
            final progress = Progress(message, stdout, LogLevel.warning);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.complete();
            verifyNever(
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}⠙')} $message... ${darkGray.wrap(time)}''',
                );
              },
            );
            verifyNever(
              () {
                stdout.write(
                  '''\b${'\b' * (message.length + 4 + time.length)}\u001b[2K${lightGreen.wrap('✓')} $message ${darkGray.wrap(time)}\n''',
                );
              },
            );
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });
    });

    group('.update', () {
      test('writes lines to stdout', () async {
        await StdioOverrides.runZoned(
          () async {
            const update = 'update';
            const time = '(0.1s)';
            final progress = Progress('message', stdout, level);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.update(update);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            verify(
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (update.length + time.length + 4)}⠹')} $update... ${darkGray.wrap(time)}''',
                );
              },
            ).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('does not writes to stdout when LogLevel > info', () async {
        await StdioOverrides.runZoned(
          () async {
            const update = 'update';
            const time = '(0.1s)';
            final progress = Progress('message', stdout, LogLevel.warning);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.update(update);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            verifyNever(
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (update.length + time.length + 4)}⠹')} $update... ${darkGray.wrap(time)}''',
                );
              },
            );
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });
    });

    group('.fail', () {
      test('writes lines to stdout', () async {
        await StdioOverrides.runZoned(
          () async {
            const time = '(0.1s)';
            const message = 'test message';
            final progress = Progress(message, stdout, level);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.fail();
            verify(
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}⠙')} $message... ${darkGray.wrap(time)}''',
                );
              },
            ).called(1);
            verify(
              () {
                stdout.write(
                  '''\b${'\b' * (message.length + 4 + time.length)}\u001b[2K${red.wrap('✗')} $message ${darkGray.wrap(time)}\n''',
                );
              },
            ).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('does not write to stdout when LogLevel > info', () async {
        await StdioOverrides.runZoned(
          () async {
            const time = '(0.1s)';
            const message = 'test message';
            final progress = Progress(message, stdout, LogLevel.warning);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.fail();
            verifyNever(
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}⠙')} $message... ${darkGray.wrap(time)}''',
                );
              },
            );
            verifyNever(
              () {
                stdout.write(
                  '''\b${'\b' * (message.length + 4 + time.length)}\u001b[2K${red.wrap('✗')} $message ${darkGray.wrap(time)}\n''',
                );
              },
            );
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });
    });

    group('.cancel', () {
      test('writes lines to stdout', () async {
        await StdioOverrides.runZoned(
          () async {
            const time = '(0.1s)';
            const message = 'test message';
            final progress = Progress(message, stdout, level);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.cancel();
            verify(
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}⠙')} $message... ${darkGray.wrap(time)}''',
                );
              },
            ).called(1);
            verify(
              () => stdout.write(
                '\b${'\b' * (message.length + 4 + time.length)}\u001b[2K',
              ),
            ).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });

      test('does not write to stdout when LogLevel > info', () async {
        await StdioOverrides.runZoned(
          () async {
            const time = '(0.1s)';
            const message = 'test message';
            final progress = Progress(message, stdout, LogLevel.warning);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.cancel();
            verifyNever(
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}⠙')} $message... ${darkGray.wrap(time)}''',
                );
              },
            );
            verifyNever(
              () => stdout.write(
                '\b${'\b' * (message.length + 4 + time.length)}\u001b[2K',
              ),
            );
          },
          stdout: () => stdout,
          stdin: () => stdin,
        );
      });
    });

    group('.call', () {
      test('writes lines to stdout', () async {
        await StdioOverrides.runZoned(
          () async {
            const time = '(0.1s)';
            const message = 'test message';
            final progress = Progress(message, stdout, level);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            // ignore: deprecated_member_use_from_same_package
            progress();
            verify(
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}⠙')} $message... ${darkGray.wrap(time)}''',
                );
              },
            ).called(1);
            verify(
              () {
                stdout.write(
                  '''\b${'\b' * (message.length + 4 + time.length)}\u001b[2K${lightGreen.wrap('✓')} $message ${darkGray.wrap(time)}\n''',
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
