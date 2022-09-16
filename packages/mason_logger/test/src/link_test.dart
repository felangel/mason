import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

void main() {
  group('link', () {
    final uri = Uri.parse('https://github.com/felangel/mason/issues/');
    const lead = '\x1B]8;;';
    const trail = '\x1B\\';

    test(
      'builds output with correct encodings: ' r'\x1B]8;;' ' and ' r'\x1B\\',
      () {
        const message = 'message';
        final output = link(message: message, uri: uri);
        final matcher = stringContainsInOrder(
          [lead, '$uri', trail, message, lead, trail],
        );

        expect(output, matcher);
      },
    );

    test('builds String with Uri when message is null: ', () {
      final output = link(uri: uri);
      final matcher = stringContainsInOrder(
        [lead, '$uri', trail, '$uri', lead, trail],
      );

      expect(output, matcher);
    });
  });
}
