// ignore_for_file: prefer_const_constructors
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
      final instance = MasonBundle('name', 'description', {}, [], []);
      expect(
        MasonBundle.fromJson(instance.toJson()),
        isA<MasonBundle>()
            .having((file) => file.name, 'name', instance.name)
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

    test('can be deserialized when hooks are null', () {
      const name = 'name';
      const description = 'description';

      expect(
        MasonBundle.fromJson(<String, dynamic>{
          'name': name,
          'description': description,
          'files': <MasonBundledFile>[],
          'vars': <String>[],
        }),
        isA<MasonBundle>()
            .having((file) => file.name, 'name', name)
            .having((file) => file.vars, 'vars', isEmpty)
            .having((file) => file.files, 'files', isEmpty)
            .having((file) => file.hooks, 'hooks', isEmpty)
            .having((file) => file.description, 'description', description),
      );
    });
  });
}
