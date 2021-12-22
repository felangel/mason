// ignore_for_file: prefer_const_constructors

import 'package:mason_cli/src/command.dart';
import 'package:test/test.dart';

void main() {
  group('Command', () {
    group('MasonYamlNameMismatch', () {
      test('has the correct message', () {
        const message = 'test message';
        expect(MasonYamlNameMismatch(message).message, equals(message));
      });
    });

    group('MasonYamlNotFoundException', () {
      test('has the correct message', () {
        const message =
            'Cannot find mason.yaml.\nDid you forget to run mason init?';
        expect(MasonYamlNotFoundException().message, equals(message));
      });
    });

    group('BrickYamlParseException', () {
      test('has the correct message', () {
        const message = 'test message';
        expect(BrickYamlParseException(message).message, equals(message));
      });
    });

    group('MasonYamlParseException', () {
      test('has the correct message', () {
        const message = 'test message';
        expect(MasonYamlParseException(message).message, equals(message));
      });
    });
  });
}
