// ignore_for_file: prefer_const_constructors
import 'package:mason/mason.dart';
import 'package:mason/src/mason_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('MasonBundledFile', () {
    test('can be (de)serialized', () {
      final instance = MasonBundledFile('.', 'data', 'text');
      expect(
        MasonBundledFile.fromJson(instance.toJson()),
        isA<MasonBundledFile>()
            .having((file) => file.data, 'data', instance.data)
            .having((file) => file.path, 'path', instance.path)
            .having((file) => file.type, 'type', instance.type),
      );
    });
  });

  group('MasonBundle', () {
    test('can be (de)serialized', () {
      final instance = MasonBundle(
        name: 'name',
        description: 'description',
        version: '1.0.0',
        vars: {},
        files: [],
        hooks: [],
      );
      expect(
        MasonBundle.fromJson(instance.toJson()),
        isA<MasonBundle>()
            .having((file) => file.name, 'name', instance.name)
            .having((file) => file.version, 'version', instance.version)
            .having((file) => file.vars, 'vars', instance.vars)
            .having((file) => file.files, 'files', instance.files)
            .having((file) => file.hooks, 'hooks', instance.hooks)
            .having(
              (file) => file.description,
              'description',
              instance.description,
            ),
      );
    });

    test('can be (de)serialized w/vars', () {
      final instance = MasonBundle(
        name: 'name',
        description: 'description',
        version: '1.0.0',
        vars: {
          'name': BrickVariableProperties.string(
            defaultValue: 'Dash',
            description: 'Your name',
            prompt: 'What is your name?',
          ),
          'age': BrickVariableProperties.number(
            defaultValue: 42,
            description: 'Your age',
            prompt: 'How old are you?',
          ),
          'isDeveloper': BrickVariableProperties.boolean(
            defaultValue: false,
            description: 'If you are a dev',
            prompt: 'Are you a developer?',
          ),
        },
        files: [],
        hooks: [],
      );
      final hasCorrectVars = equals({
        'name': isA<BrickVariableProperties>()
            .having((v) => v.type, 'type', BrickVariableType.string)
            .having((v) => v.defaultValue, 'defaultValue', 'Dash')
            .having((v) => v.description, 'description', 'Your name')
            .having((v) => v.prompt, 'prompt', 'What is your name?'),
        'age': isA<BrickVariableProperties>()
            .having((v) => v.type, 'type', BrickVariableType.number)
            .having((v) => v.defaultValue, 'defaultValue', 42)
            .having((v) => v.description, 'description', 'Your age')
            .having((v) => v.prompt, 'prompt', 'How old are you?'),
        'isDeveloper': isA<BrickVariableProperties>()
            .having((v) => v.type, 'type', BrickVariableType.boolean)
            .having((v) => v.defaultValue, 'defaultValue', false)
            .having((v) => v.description, 'description', 'If you are a dev')
            .having((v) => v.prompt, 'prompt', 'Are you a developer?'),
      });
      expect(
        MasonBundle.fromJson(instance.toJson()),
        isA<MasonBundle>()
            .having((file) => file.name, 'name', instance.name)
            .having((file) => file.version, 'version', instance.version)
            .having((file) => file.vars, 'vars', hasCorrectVars)
            .having((file) => file.files, 'files', instance.files)
            .having((file) => file.hooks, 'hooks', instance.hooks)
            .having(
              (file) => file.description,
              'description',
              instance.description,
            ),
      );
    });

    test('can be deserialized when hooks are null', () {
      const name = 'name';
      const description = 'description';
      const version = '1.0.0';

      expect(
        MasonBundle.fromJson(<String, dynamic>{
          'name': name,
          'description': description,
          'version': version,
          'files': <MasonBundledFile>[],
          'vars': <String>[],
        }),
        isA<MasonBundle>()
            .having((file) => file.name, 'name', name)
            .having((file) => file.version, 'version', version)
            .having((file) => file.vars, 'vars', isEmpty)
            .having((file) => file.files, 'files', isEmpty)
            .having((file) => file.hooks, 'hooks', isEmpty)
            .having((file) => file.description, 'description', description),
      );
    });

    test('can be converted to/from universal bundle', () {
      final instance = MasonBundle(
        name: 'name',
        description: 'description',
        version: '1.0.0',
        vars: {},
        files: [],
        hooks: [],
      );
      expect(
        MasonBundle.fromUniversalBundle(instance.toUniversalBundle()),
        isA<MasonBundle>()
            .having((file) => file.name, 'name', instance.name)
            .having((file) => file.version, 'version', instance.version)
            .having((file) => file.vars, 'vars', instance.vars)
            .having((file) => file.files, 'files', instance.files)
            .having((file) => file.hooks, 'hooks', instance.hooks)
            .having(
              (file) => file.description,
              'description',
              instance.description,
            ),
      );
    });
  });
}
