import 'dart:io';

import 'package:mason_logger/src/stdio_overrides.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class FakeStdout extends Fake implements Stdout {}

class FakeStdin extends Fake implements Stdin {}

void main() {
  group('StdioOverrides', () {
    group('runZoned', () {
      test('uses default stdioType when not specified', () {
        StdioOverrides.runZoned(() {
          final overrides = StdioOverrides.current;
          expect(overrides!.stdioType, equals(stdioType));
        });
      });

      test('uses custom stdioType when specified', () {
        StdioType customStdioType(dynamic _) => StdioType.pipe;
        StdioOverrides.runZoned(
          () {
            final overrides = StdioOverrides.current;
            expect(overrides!.stdioType, equals(customStdioType));
          },
          stdioType: () => customStdioType,
        );
      });

      test(
          'uses current stdioType when not specified '
          'and zone already contains a stdioType', () {
        StdioType customStdioType(dynamic _) => StdioType.pipe;
        StdioOverrides.runZoned(
          () {
            StdioOverrides.runZoned(() {
              final overrides = StdioOverrides.current;
              expect(overrides!.stdioType, equals(customStdioType));
            });
          },
          stdioType: () => customStdioType,
        );
      });

      test(
          'uses nested stdioType when specified '
          'and zone already contains a stdioType', () {
        StdioType rootStdioType(dynamic _) => StdioType.pipe;
        StdioOverrides.runZoned(
          () {
            StdioType nestedStdioType(dynamic _) => StdioType.other;
            final overrides = StdioOverrides.current;
            expect(overrides!.stdioType, equals(rootStdioType));
            StdioOverrides.runZoned(
              () {
                final overrides = StdioOverrides.current;
                expect(overrides!.stdioType, equals(nestedStdioType));
              },
              stdioType: () => nestedStdioType,
            );
          },
          stdioType: () => rootStdioType,
        );
      });
    });
  });
}
