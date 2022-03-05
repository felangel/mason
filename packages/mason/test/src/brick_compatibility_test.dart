import 'package:mason/mason.dart';
import 'package:test/test.dart';

void main() {
  BrickYaml getBrickYaml(String constraint) {
    return BrickYaml(
      name: 'example',
      description: 'example',
      version: '0.1.0',
      environment: BrickEnvironment(mason: constraint),
    );
  }

  group('isBrickCompatibleWithMason', () {
    test('returns true when constraint is any', () {
      expect(
        isBrickCompatibleWithMason(getBrickYaml('any')),
        isTrue,
      );
    });

    test('returns true when constraint is ^{currentVersion}', () {
      expect(
        isBrickCompatibleWithMason(getBrickYaml('^$packageVersion')),
        isTrue,
      );
    });

    test('returns true when constraint is {currentVersion}', () {
      expect(
        isBrickCompatibleWithMason(getBrickYaml(packageVersion)),
        isTrue,
      );
    });

    // Avoid using double quotes in test descriptions.
    // Ref: https://github.com/Dart-Code/Dart-Code/issues/3863
    test("returns true when constraint is '>={currentVersion}'", () {
      expect(
        isBrickCompatibleWithMason(getBrickYaml('>=$packageVersion')),
        isTrue,
      );
    });

    test('returns false when constraint is 0.0.0', () {
      expect(
        isBrickCompatibleWithMason(getBrickYaml('0.0.0')),
        isFalse,
      );
    });

    test('returns false when constraint is ^0.0.0', () {
      expect(
        isBrickCompatibleWithMason(getBrickYaml('^0.0.0')),
        isFalse,
      );
    });

    test('returns false when constraint is >=0.0.0 <0.0.1', () {
      expect(
        isBrickCompatibleWithMason(getBrickYaml('>=0.0.0 <0.0.1')),
        isFalse,
      );
    });
  });
}
