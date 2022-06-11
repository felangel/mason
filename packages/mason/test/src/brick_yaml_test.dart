// ignore_for_file: prefer_const_constructors

import 'package:checked_yaml/checked_yaml.dart';
import 'package:mason/mason.dart';
import 'package:test/test.dart';

Matcher equalsBrickVariableProperties({
  required BrickVariableType type,
  String? description,
  Object? defaultValue,
  List<String>? defaultValues,
  String? prompt,
  List<String>? values,
}) {
  return isA<BrickVariableProperties>()
      .having((v) => v.type, 'type', type)
      .having((v) => v.description, 'description', description)
      .having((v) => v.defaultValue, 'default', defaultValue)
      .having((v) => v.defaultValues, 'defaults', defaultValues)
      .having((v) => v.prompt, 'prompt', prompt)
      .having((v) => v.values, 'values', values);
}

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

      test('can be (de)serialized correctly with repository', () {
        final instance = BrickYaml(
          name: 'A',
          description: 'descriptionA',
          version: '1.0.0',
          repository: 'https://github.com/felangel/mason',
        );
        expect(BrickYaml.fromJson(instance.toJson()), equals(instance));
      });

      test('can be (de)serialized correctly with vars', () {
        final instance = BrickYaml(
          name: 'A',
          description: 'descriptionA',
          version: '1.0.0',
          // ignore: prefer_const_literals_to_create_immutables
          vars: {
            'name': BrickVariableProperties.string(
              description: 'the name',
              defaultValue: 'Dash',
              prompt: 'What is your name?',
            ),
            'age': BrickVariableProperties.number(
              description: 'the age',
              defaultValue: 42,
              prompt: 'How old are you?',
            ),
            'isDeveloper': BrickVariableProperties.boolean(
              description: 'whether you are a developer',
              defaultValue: true,
              prompt: 'Are you a developer?',
            ),
            'favoriteColor': BrickVariableProperties.enumeration(
              description: 'whether you are a developer',
              defaultValue: 'blue',
              prompt: 'Are you a developer?',
              values: const ['red', 'blue', 'green'],
            ),
            'flavors': BrickVariableProperties.array(
              description: 'supported flavors',
              defaultValues: const ['dev'],
              prompt: 'What flavors do you want?',
              values: const ['dev', 'prod'],
            ),
          },
        );
        expect(BrickYaml.fromJson(instance.toJson()), equals(instance));
      });

      test('supports simple json format', () {
        const content = '''
name: A
description: descriptionA
version: '1.0.0'
vars:
  - name
  - age
  - isDeveloper
          ''';

        final brickYaml = checkedYamlDecode(
          content,
          (v) => BrickYaml.fromJson(v!),
        );
        expect(brickYaml.name, equals('A'));
        expect(brickYaml.description, equals('descriptionA'));
        expect(brickYaml.version, equals('1.0.0'));
        expect(brickYaml.vars.keys, equals(['name', 'age', 'isDeveloper']));
        expect(
          brickYaml.vars.values,
          equals([
            equalsBrickVariableProperties(type: BrickVariableType.string),
            equalsBrickVariableProperties(type: BrickVariableType.string),
            equalsBrickVariableProperties(type: BrickVariableType.string),
          ]),
        );
      });

      test('supports complex json format', () {
        const content = '''
name: A
description: descriptionA
version: '1.0.0'
vars:
  name:
    type: string
    description: the name
    default: Dash
    prompt: What is your name?
  age:
    type: number
    description: the age
    default: 42
    prompt: How old are you?
  isDeveloper:
    type: boolean
    description: whether you are a developer
    default: true
    prompt: Are you a developer?
  favoriteColor:
    type: enum
    description: your favorite color
    default: green
    prompt: What is your favorite color?
    values:
      - red
      - green
      - blue
  flavors:
    type: array
    description: supported flavors
    defaults:
      - dev
    prompt: What flavors do you want?
    values:
      - dev
      - prod''';

        final brickYaml = checkedYamlDecode(
          content,
          (v) => BrickYaml.fromJson(v!),
        );
        expect(brickYaml.name, equals('A'));
        expect(brickYaml.description, equals('descriptionA'));
        expect(brickYaml.version, equals('1.0.0'));
        expect(
          brickYaml.vars.keys,
          equals(['name', 'age', 'isDeveloper', 'favoriteColor', 'flavors']),
        );
        expect(
          brickYaml.vars.values,
          equals([
            equalsBrickVariableProperties(
              type: BrickVariableType.string,
              description: 'the name',
              defaultValue: 'Dash',
              prompt: 'What is your name?',
            ),
            equalsBrickVariableProperties(
              type: BrickVariableType.number,
              description: 'the age',
              defaultValue: 42,
              prompt: 'How old are you?',
            ),
            equalsBrickVariableProperties(
              type: BrickVariableType.boolean,
              description: 'whether you are a developer',
              defaultValue: true,
              prompt: 'Are you a developer?',
            ),
            equalsBrickVariableProperties(
              type: BrickVariableType.enumeration,
              description: 'your favorite color',
              defaultValue: 'green',
              prompt: 'What is your favorite color?',
              values: ['red', 'green', 'blue'],
            ),
            equalsBrickVariableProperties(
              type: BrickVariableType.array,
              description: 'supported flavors',
              defaultValues: ['dev'],
              prompt: 'What flavors do you want?',
              values: ['dev', 'prod'],
            ),
          ]),
        );
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
