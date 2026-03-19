import 'package:masonex/masonex.dart';
import 'package:test/test.dart';

void main() {
  BrickYaml getBrickYaml(String constraint) {
    return BrickYaml(
      name: 'example',
      description: 'example',
      version: '0.1.0',
      environment: BrickEnvironment(masonex: constraint),
    );
  }

  group('isBrickCompatibleWithMasonex', () {
    test('returns true when constraint is any', () {
      expect(
        isBrickCompatibleWithMasonex(getBrickYaml('any')),
        isTrue,
      );
    });

    test('returns true when constraint is ^{currentVersion}', () {
      expect(
        isBrickCompatibleWithMasonex(getBrickYaml('^$packageVersion')),
        isTrue,
      );
    });

    test('returns true when constraint is {currentVersion}', () {
      expect(
        isBrickCompatibleWithMasonex(getBrickYaml(packageVersion)),
        isTrue,
      );
    });

    test('returns true when constraint is ">={currentVersion}"', () {
      expect(
        isBrickCompatibleWithMasonex(getBrickYaml('>=$packageVersion')),
        isTrue,
      );
    });

    test('returns false when constraint is 0.0.0', () {
      expect(
        isBrickCompatibleWithMasonex(getBrickYaml('0.0.0')),
        isFalse,
      );
    });

    test('returns false when constraint is ^0.0.0', () {
      expect(
        isBrickCompatibleWithMasonex(getBrickYaml('^0.0.0')),
        isFalse,
      );
    });

    test('returns false when constraint is >=0.0.0 <0.0.1', () {
      expect(
        isBrickCompatibleWithMasonex(getBrickYaml('>=0.0.0 <0.0.1')),
        isFalse,
      );
    });
  });
}
