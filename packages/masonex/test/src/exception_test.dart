// ignore_for_file: prefer_const_constructors

import 'package:masonex/masonex.dart';
import 'package:masonex/src/bricks_json.dart';
import 'package:test/test.dart';

void main() {
  group('Exception', () {
    group('MasonexException', () {
      test('can be instantiated', () {
        const message = 'test message';
        final exception = MasonexException(message);
        expect(exception.message, equals(message));
      });

      test('overrides toString()', () {
        const message = 'test message';
        final exception = MasonexException(message);
        expect(exception.toString(), equals(message));
      });
    });

    group('BrickResolveVersionException', () {
      test('can be instantiated', () {
        const message = 'test message';
        final exception = BrickResolveVersionException(message);
        expect(exception.message, equals(message));
      });
    });

    group('BrickUnsatisfiedVersionConstraint', () {
      test('can be instantiated', () {
        const message = 'test message';
        final exception = BrickUnsatisfiedVersionConstraint(message);
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

    group('MasonexYamlNameMismatch', () {
      test('has the correct message', () {
        const message = 'test message';
        expect(MasonexYamlNameMismatch(message).message, equals(message));
      });
    });
  });
}
