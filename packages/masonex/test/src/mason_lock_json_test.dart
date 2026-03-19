// ignore_for_file: prefer_const_constructors

import 'package:masonex/masonex.dart';
import 'package:test/test.dart';

void main() {
  group('MasonexLockJson', () {
    test('can be (de)serialized', () {
      final brickLocation = BrickLocation(path: '.');
      final instance = MasonexLockJson(
        bricks: {'example': brickLocation},
      );
      final result = MasonexLockJson.fromJson(instance.toJson());
      expect(result.bricks.length, equals(1));
      expect(result.bricks.keys.first, equals('example'));
      expect(
        result.bricks.values.first,
        isA<BrickLocation>().having((b) => b.path, 'path', brickLocation.path),
      );
    });
  });
}
