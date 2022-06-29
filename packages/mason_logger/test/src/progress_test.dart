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
    late Stdout stderr;

    setUp(() {
      stdout = MockStdout();
      stdin = MockStdin();
      stderr = MockStdout();
    });

    group('.complete', () {
      test('writes lines to stdout', () async {
        await StdioOverrides.runZoned(
          () async {
            const message = 'test message';
            final progress = Progress(message, stdout, stderr);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.complete();
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
          stderr: () => stderr,
        );
      });
    });

    group('.update', () {
      test('writes lines to stdout', () async {
        await StdioOverrides.runZoned(
          () async {
            const update = 'update';
            const time = '(0.1s)';
            final progress = Progress('message', stdout, stderr);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.update(update);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            verify(
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (update.length + time.length + 5)}⠹')} $update ${darkGray.wrap(time)}...''',
                );
              },
            ).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
          stderr: () => stderr,
        );
      });
    });

    group('.fail', () {
      test('writes lines to stderr', () async {
        await StdioOverrides.runZoned(
          () async {
            const message = 'test message';
            final progress = Progress(message, stdout, stderr);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.fail();
            verify(
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (message.length + 4)}⠙')} $message...''',
                );
              },
            ).called(1);
            verify(
              () {
                stderr.write(
                  '''\b${'\b' * (message.length + 4)}\u001b[2K${red.wrap('✗')} $message ${darkGray.wrap('(0.1s)')}\n''',
                );
              },
            ).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
          stderr: () => stderr,
        );
      });
    });

    group('.cancel', () {
      test('writes lines to stdout', () async {
        await StdioOverrides.runZoned(
          () async {
            const message = 'test message';
            final progress = Progress(message, stdout, stderr);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            progress.cancel();
            verify(
              () {
                stdout.write(
                  '''${lightGreen.wrap('\b${'\b' * (message.length + 4)}⠙')} $message...''',
                );
              },
            ).called(1);
            verify(
              () => stdout.write('\b${'\b' * (message.length + 4)}\u001b[2K'),
            ).called(1);
          },
          stdout: () => stdout,
          stdin: () => stdin,
          stderr: () => stderr,
        );
      });
    });

    group('.call', () {
      test('writes lines to stdout', () async {
        await StdioOverrides.runZoned(
          () async {
            const message = 'test message';
            final progress = Progress(message, stdout, stderr);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            // ignore: deprecated_member_use_from_same_package
            progress();
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
          stderr: () => stderr,
        );
      });
    });
  });
}
