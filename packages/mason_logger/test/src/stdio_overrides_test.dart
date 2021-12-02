import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

class FakeStdout extends Fake implements Stdout {}

class FakeStdin extends Fake implements Stdin {}

void main() {
  group('StdioOverrides', () {
    group('runZoned', () {
      test('uses default Stdout when not specified', () {
        StdioOverrides.runZoned(() {
          final overrides = StdioOverrides.current;
          expect(overrides!.stdout, isA<Stdout>());
        });
      });

      test('uses default Stdin when not specified', () {
        StdioOverrides.runZoned(() {
          final overrides = StdioOverrides.current;
          expect(overrides!.stdin, isA<Stdin>());
        });
      });

      test('uses custom Stdout when specified', () {
        final stdout = FakeStdout();
        StdioOverrides.runZoned(
          () {
            final overrides = StdioOverrides.current;
            expect(overrides!.stdout, equals(stdout));
          },
          stdout: () => stdout,
        );
      });

      test('uses custom Stdin when specified', () {
        final stdin = FakeStdin();
        StdioOverrides.runZoned(
          () {
            final overrides = StdioOverrides.current;
            expect(overrides!.stdin, equals(stdin));
          },
          stdin: () => stdin,
        );
      });

      test(
          'uses current Stdout when not specified '
          'and zone already contains a Stdout', () {
        final stdout = FakeStdout();
        StdioOverrides.runZoned(
          () {
            StdioOverrides.runZoned(() {
              final overrides = StdioOverrides.current;
              expect(overrides!.stdout, equals(stdout));
            });
          },
          stdout: () => stdout,
        );
      });

      test(
          'uses current Stdin when not specified '
          'and zone already contains an Stdin', () {
        final stdin = FakeStdin();
        StdioOverrides.runZoned(
          () {
            StdioOverrides.runZoned(() {
              final overrides = StdioOverrides.current;
              expect(overrides!.stdin, equals(stdin));
            });
          },
          stdin: () => stdin,
        );
      });

      test(
          'uses nested Stdout when specified '
          'and zone already contains a Stdout', () {
        final rootStdout = FakeStdout();
        StdioOverrides.runZoned(
          () {
            final nestedStdout = FakeStdout();
            final overrides = StdioOverrides.current;
            expect(overrides!.stdout, equals(rootStdout));
            StdioOverrides.runZoned(
              () {
                final overrides = StdioOverrides.current;
                expect(overrides!.stdout, equals(nestedStdout));
              },
              stdout: () => nestedStdout,
            );
          },
          stdout: () => rootStdout,
        );
      });

      test(
          'uses nested Stdin when specified '
          'and zone already contains a Stdin', () {
        final rootStdin = FakeStdin();
        StdioOverrides.runZoned(
          () {
            final nestedStdin = FakeStdin();
            final overrides = StdioOverrides.current;
            expect(overrides!.stdin, equals(rootStdin));
            StdioOverrides.runZoned(
              () {
                final overrides = StdioOverrides.current;
                expect(overrides!.stdin, equals(nestedStdin));
              },
              stdin: () => nestedStdin,
            );
          },
          stdin: () => rootStdin,
        );
      });
    });
  });
}
