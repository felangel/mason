// ignore_for_file: prefer_const_constructors
import 'dart:convert';

import 'package:mason/mason.dart';
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
            )
            .having(
              (file) => file.environment.mason,
              'environment.mason',
              instance.environment.mason,
            ),
      );
    });

    test('can be (de)serialized w/repository', () {
      final instance = MasonBundle(
        name: 'name',
        description: 'description',
        repository: 'https://github.com/felangel/mason',
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
            .having(
              (file) => file.repository,
              'repository',
              instance.repository,
            )
            .having((file) => file.vars, 'vars', instance.vars)
            .having((file) => file.files, 'files', instance.files)
            .having((file) => file.hooks, 'hooks', instance.hooks)
            .having(
              (file) => file.description,
              'description',
              instance.description,
            )
            .having(
              (file) => file.environment.mason,
              'environment.mason',
              instance.environment.mason,
            ),
      );
    });

    test('can be (de)serialized w/custom environment', () {
      final instance = MasonBundle(
        name: 'name',
        description: 'description',
        version: '1.0.0',
        environment: BrickEnvironment(mason: '>=0.1.0-dev <0.1.0'),
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
            )
            .having(
              (file) => file.environment.mason,
              'environment.mason',
              instance.environment.mason,
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

    test('can be deserialized w/readme, changelog, and license', () {
      const name = 'name';
      const description = 'description';
      const version = '1.0.0';
      final bundledFile = MasonBundledFile('.', 'data', 'text');

      final isBundledFile = isA<MasonBundledFile>()
          .having((b) => b.path, 'path', bundledFile.path)
          .having((b) => b.data, 'data', bundledFile.data)
          .having((b) => b.type, 'type', bundledFile.type);

      expect(
        MasonBundle.fromJson(<String, dynamic>{
          'name': name,
          'description': description,
          'version': version,
          'files': <MasonBundledFile>[],
          'vars': <String>[],
          'readme': bundledFile.toJson(),
          'changelog': bundledFile.toJson(),
          'license': bundledFile.toJson(),
        }),
        isA<MasonBundle>()
            .having((file) => file.name, 'name', name)
            .having((file) => file.version, 'version', version)
            .having((file) => file.vars, 'vars', isEmpty)
            .having((file) => file.files, 'files', isEmpty)
            .having((file) => file.hooks, 'hooks', isEmpty)
            .having((file) => file.description, 'description', description)
            .having((file) => file.readme, 'readme', isBundledFile)
            .having((file) => file.changelog, 'changelog', isBundledFile)
            .having((file) => file.license, 'license', isBundledFile),
      );
    });

    test('can be converted to/from universal bundle', () async {
      final instance = MasonBundle(
        name: 'name',
        description: 'description',
        version: '1.0.0',
        vars: {},
        files: [],
        hooks: [],
      );
      expect(
        await MasonBundle.fromUniversalBundle(
          await instance.toUniversalBundle(),
        ),
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

    test('can be converted to/from dart bundle', () async {
      final instance = MasonBundle(
        name: 'name',
        description: 'description',
        version: '1.0.0',
        vars: {},
        files: [],
        hooks: [],
      );
      expect(
        await MasonBundle.fromDartBundle(jsonEncode(instance.toJson())),
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
