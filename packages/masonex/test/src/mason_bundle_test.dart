// ignore_for_file: prefer_const_constructors
import 'dart:convert';

import 'package:masonex/masonex.dart';
import 'package:test/test.dart';

void main() {
  group('MasonexBundledFile', () {
    test('can be (de)serialized', () {
      final instance = MasonexBundledFile('.', 'data', 'text');
      expect(
        MasonexBundledFile.fromJson(instance.toJson()),
        isA<MasonexBundledFile>()
            .having((file) => file.data, 'data', instance.data)
            .having((file) => file.path, 'path', instance.path)
            .having((file) => file.type, 'type', instance.type),
      );
    });
  });

  group('MasonexBundle', () {
    test('can be (de)serialized', () {
      final instance = MasonexBundle(
        name: 'name',
        description: 'description',
        version: '1.0.0',
        vars: {},
        files: [],
        hooks: [],
      );
      expect(
        MasonexBundle.fromJson(instance.toJson()),
        isA<MasonexBundle>()
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
              (file) => file.environment.masonex,
              'environment.masonex',
              instance.environment.masonex,
            ),
      );
    });

    test('can be (de)serialized w/repository', () {
      final instance = MasonexBundle(
        name: 'name',
        description: 'description',
        repository: 'https://github.com/felangel/masonex',
        version: '1.0.0',
        vars: {},
        files: [],
        hooks: [],
      );
      expect(
        MasonexBundle.fromJson(instance.toJson()),
        isA<MasonexBundle>()
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
              (file) => file.environment.masonex,
              'environment.masonex',
              instance.environment.masonex,
            ),
      );
    });

    test('can be (de)serialized w/publishTo', () {
      final instance = MasonexBundle(
        name: 'name',
        description: 'description',
        publishTo: 'https://custom.brickhub.dev',
        version: '1.0.0',
        vars: {},
        files: [],
        hooks: [],
      );
      expect(
        MasonexBundle.fromJson(instance.toJson()),
        isA<MasonexBundle>()
            .having((file) => file.name, 'name', instance.name)
            .having((file) => file.version, 'version', instance.version)
            .having(
              (file) => file.publishTo,
              'publishTo',
              instance.publishTo,
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
              (file) => file.environment.masonex,
              'environment.masonex',
              instance.environment.masonex,
            ),
      );
    });

    test('can be (de)serialized w/custom environment', () {
      final instance = MasonexBundle(
        name: 'name',
        description: 'description',
        version: '1.0.0',
        environment: BrickEnvironment(masonex: '>=0.1.0-dev <0.1.0'),
        vars: {},
        files: [],
        hooks: [],
      );
      expect(
        MasonexBundle.fromJson(instance.toJson()),
        isA<MasonexBundle>()
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
              (file) => file.environment.masonex,
              'environment.masonex',
              instance.environment.masonex,
            ),
      );
    });

    test('can be (de)serialized w/vars', () {
      final instance = MasonexBundle(
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
        MasonexBundle.fromJson(instance.toJson()),
        isA<MasonexBundle>()
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
        MasonexBundle.fromJson(<String, dynamic>{
          'name': name,
          'description': description,
          'version': version,
          'files': <MasonexBundledFile>[],
          'vars': <String>[],
        }),
        isA<MasonexBundle>()
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
      final bundledFile = MasonexBundledFile('.', 'data', 'text');

      final isBundledFile = isA<MasonexBundledFile>()
          .having((b) => b.path, 'path', bundledFile.path)
          .having((b) => b.data, 'data', bundledFile.data)
          .having((b) => b.type, 'type', bundledFile.type);

      expect(
        MasonexBundle.fromJson(<String, dynamic>{
          'name': name,
          'description': description,
          'version': version,
          'files': <MasonexBundledFile>[],
          'vars': <String>[],
          'readme': bundledFile.toJson(),
          'changelog': bundledFile.toJson(),
          'license': bundledFile.toJson(),
        }),
        isA<MasonexBundle>()
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
      final instance = MasonexBundle(
        name: 'name',
        description: 'description',
        version: '1.0.0',
        vars: {},
        files: [],
        hooks: [],
      );
      expect(
        await MasonexBundle.fromUniversalBundle(
          await instance.toUniversalBundle(),
        ),
        isA<MasonexBundle>()
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
      final instance = MasonexBundle(
        name: 'name',
        description: 'description',
        version: '1.0.0',
        vars: {},
        files: [],
        hooks: [],
      );
      expect(
        await MasonexBundle.fromDartBundle(jsonEncode(instance.toJson())),
        isA<MasonexBundle>()
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
