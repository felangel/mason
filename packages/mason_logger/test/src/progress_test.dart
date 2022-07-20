import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStdout extends Mock implements Stdout {}

class MockStdin extends Mock implements Stdin {}

void main() {
  group('Progress', () {
    late Stdout stdout;

    setUp(() {
      stdout = MockStdout();
    });

    group('.complete', () {
      test('writes lines to stdout', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const time = '(0.1s)';
                const message = 'test message';
                final progress = Logger().progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.complete();
                verify(
                  () {
                    stdout.write(
                      '''[92m⠙[0m $message... [90m$time[0m''',
                    );
                  },
                ).called(1);
                verify(
                  () {
                    stdout.write(
                      '''[2K[92m✓[0m $message [90m$time[0m\n''',
                    );
                  },
                ).called(1);
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });

      test('does not write lines to stdout when Level > info', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const message = 'test message';
                final progress = Logger(level: Level.warning).progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.complete();
                verifyNever(() => stdout.write(any()));
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });
    });

    group('.update', () {
      test('writes lines to stdout', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const message = 'message';
                const update = 'update';
                const time = '(0.1s)';
                final progress = Logger().progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.update(update);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                verify(
                  () {
                    stdout.write(
                      '''[92m⠙[0m $message... [90m$time[0m''',
                    );
                  },
                ).called(1);
                verify(
                  () {
                    stdout.write(
                      '''[92m⠹[0m $update... [90m$time[0m''',
                    );
                  },
                ).called(1);
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });

      test('does not writes to stdout when Level > info', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
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
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });
    });

    group('.fail', () {
      test('writes lines to stdout', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const time = '(0.1s)';
                const message = 'test message';
                final progress = Logger().progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.fail();
                verify(
                  () {
                    stdout.write(
                      '''[92m⠙[0m $message... [90m$time[0m''',
                    );
                  },
                ).called(1);
                verify(
                  () {
                    stdout.write(
                      '''[2K[31m✗[0m $message [90m$time[0m\n''',
                    );
                  },
                ).called(1);
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });

      test('does not write to stdout when Level > info', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const message = 'test message';
                final progress = Logger(level: Level.warning).progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.fail();
                verifyNever(() => stdout.write(any()));
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });
    });

    group('.cancel', () {
      test('writes lines to stdout', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const time = '(0.1s)';
                const message = 'test message';
                final progress = Logger().progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.cancel();
                verify(
                  () {
                    stdout.write(
                      '''[92m⠙[0m $message... [90m$time[0m''',
                    );
                  },
                ).called(1);
                verify(
                  () {
                    stdout.write(
                      '''[2K''',
                    );
                  },
                ).called(1);
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });

      test('does not write to stdout when Level > info', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const message = 'test message';
                final progress = Logger(level: Level.warning).progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.cancel();
                verifyNever(() => stdout.write(any()));
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });
    });
  });
}
