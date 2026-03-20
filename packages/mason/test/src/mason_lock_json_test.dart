// ignore_for_file: prefer_const_constructors

import 'package:mason/mason.dart';
import 'package:test/test.dart';

void main() {
  group('MasonLockJson', () {
    test('can be (de)serialized', () {
      final brickLocation = BrickLocation(path: '.');
      final instance = MasonLockJson(
        bricks: {'example': brickLocation},
      );
      final result = MasonLockJson.fromJson(instance.toJson());
      expect(result.bricks.length, equals(1));
      expect(result.bricks.keys.first, equals('example'));
      expect(
        result.bricks.values.first,
        isA<BrickLocation>().having((b) => b.path, 'path', brickLocation.path),
      );
    });
  });
}
