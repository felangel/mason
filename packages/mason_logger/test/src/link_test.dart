import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockStdout extends Mock implements Stdout {}

void main() {
  group('link', () {
    late Stdout stdout;
    late Stdout stderr;

    setUp(() {
      stdout = _MockStdout();
      stderr = _MockStdout();
      when(() => stdout.supportsAnsiEscapes).thenReturn(true);
      when(() => stderr.supportsAnsiEscapes).thenReturn(true);
    });

    R runWithOverrides<R>(R Function() body) {
      return IOOverrides.runZoned(
        body,
        stdout: () => stdout,
        stderr: () => stderr,
      );
    }

    final uri = Uri.parse('https://github.com/felangel/mason/issues/');
    const lead = '\x1B]8;;';
    const trail = '\x1B\\';

    test(
      'builds output with correct encodings: ' r'\x1B]8;;' ' and ' r'\x1B\\',
      () {
        const message = 'message';
        final output = runWithOverrides(() => link(message: message, uri: uri));
        final matcher = stringContainsInOrder(
          [lead, '$uri', trail, message, lead, trail],
        );

        expect(output, matcher);
      },
    );

    test('builds String with Uri when message is null: ', () {
      final output = runWithOverrides(() => link(uri: uri));
      final matcher = stringContainsInOrder(
        [lead, '$uri', trail, '$uri', lead, trail],
      );

      expect(output, matcher);
    });

    test('builds output when ansi escapes are not supported', () {
      when(() => stdout.supportsAnsiEscapes).thenReturn(false);
      when(() => stderr.supportsAnsiEscapes).thenReturn(false);
      final output = runWithOverrides(() => link(uri: uri));
      final matcher = stringContainsInOrder(['$uri']);
      expect(output, matcher);
    });

    test('builds output with message when ansi escapes are not supported', () {
      when(() => stdout.supportsAnsiEscapes).thenReturn(false);
      when(() => stderr.supportsAnsiEscapes).thenReturn(false);
      const message = 'message';
      final output = runWithOverrides(() => link(uri: uri, message: message));
      expect(output, equals('[$message]($uri)'));
    });
  });
}
