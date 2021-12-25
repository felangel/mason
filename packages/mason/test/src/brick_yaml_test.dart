// ignore_for_file: prefer_const_constructors

import 'package:mason/mason.dart';
import 'package:test/test.dart';

void main() {
  group('BrickYaml', () {
    group('to/from json', () {
      test('can be (de)serialized correctly with path', () {
        final instance = BrickYaml('A', 'descriptionA', path: '.');
        expect(BrickYaml.fromJson(instance.toJson()), equals(instance));
      });

      test('can be (de)serialized correctly without path', () {
        final instance = BrickYaml('A', 'descriptionA');
        expect(BrickYaml.fromJson(instance.toJson()), equals(instance));
      });
    });

    group('copyWith', () {
      test('returns a copy when no path is provided', () {
        final instance = BrickYaml('A', 'descriptionA');
        expect(instance.copyWith(), equals(instance));
      });

      test('returns a copy when path is provided', () {
        final instance = BrickYaml('A', 'descriptionA');
        final copy = instance.copyWith(path: '.');
        expect(copy, equals(instance));
        expect(copy.path, equals('.'));
      });
    });

    group('==', () {
      test('returns true when names are the same', () {
        final instanceA = BrickYaml('A', 'descriptionA');
        final instanceB = BrickYaml('A', 'descriptionB');
        expect(instanceA, equals(instanceB));
      });

      test('returns false when names are different', () {
        final instanceA = BrickYaml('A', 'description');
        final instanceB = BrickYaml('B', 'description');
        expect(instanceA, isNot(equals(instanceB)));
      });
    });

    group('hashCode', () {
      test('equals name.hashCode', () {
        final instanceA = BrickYaml('A', 'descriptionA');
        expect(instanceA.hashCode, equals(instanceA.name.hashCode));
      });
    });
  });
}
