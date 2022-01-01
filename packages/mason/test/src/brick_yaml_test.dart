// ignore_for_file: prefer_const_constructors

import 'package:mason/mason.dart';
import 'package:test/test.dart';

void main() {
  group('BrickYaml', () {
    group('to/from json', () {
      test('can be (de)serialized correctly with path', () {
        final instance = BrickYaml(
          name: 'A',
          description: 'descriptionA',
          version: '1.0.0',
          path: '.',
        );
        expect(BrickYaml.fromJson(instance.toJson()), equals(instance));
      });

      test('can be (de)serialized correctly without path', () {
        final instance = BrickYaml(
          name: 'A',
          description: 'descriptionA',
          version: '1.0.0',
        );
        expect(BrickYaml.fromJson(instance.toJson()), equals(instance));
      });
    });

    group('copyWith', () {
      test('returns a copy when no path is provided', () {
        final instance = BrickYaml(
          name: 'A',
          description: 'descriptionA',
          version: '1.0.0',
        );
        expect(instance.copyWith(), equals(instance));
      });

      test('returns a copy when path is provided', () {
        final instance = BrickYaml(
          name: 'A',
          description: 'descriptionA',
          version: '1.0.0',
        );
        final copy = instance.copyWith(path: '.');
        expect(copy, equals(instance));
        expect(copy.path, equals('.'));
      });
    });

    group('==', () {
      test('returns true when names are the same', () {
        final instanceA = BrickYaml(
          name: 'A',
          description: 'descriptionA',
          version: '1.0.0',
        );
        final instanceB = BrickYaml(
          name: 'A',
          description: 'descriptionB',
          version: '1.0.0',
        );
        expect(instanceA, equals(instanceB));
      });

      test('returns false when names are different', () {
        final instanceA = BrickYaml(
          name: 'A',
          description: 'description',
          version: '1.0.0',
        );
        final instanceB = BrickYaml(
          name: 'B',
          description: 'description',
          version: '1.0.0',
        );
        expect(instanceA, isNot(equals(instanceB)));
      });
    });

    group('hashCode', () {
      test('equals name.hashCode', () {
        final instanceA = BrickYaml(
          name: 'A',
          description: 'descriptionA',
          version: '1.0.0',
        );
        expect(instanceA.hashCode, equals(instanceA.name.hashCode));
      });
    });
  });
}
