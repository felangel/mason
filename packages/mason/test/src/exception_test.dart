// ignore_for_file: prefer_const_constructors

import 'package:mason/mason.dart';
import 'package:test/test.dart';

void main() {
  group('Exception', () {
    group('MasonException', () {
      test('can be instantiated', () {
        const message = 'test message';
        final exception = MasonException(message);
        expect(exception.message, equals(message));
      });
    });

    group('WriteBrickException', () {
      test('can be instantiated', () {
        const message = 'test message';
        final exception = WriteBrickException(message);
        expect(exception.message, equals(message));
      });
    });

    group('BrickNotFoundException', () {
      test('can be instantiated', () {
        const path = 'test path';
        final exception = BrickNotFoundException(path);
        expect(exception.message, equals('Could not find brick at $path'));
      });
    });
  });
}
