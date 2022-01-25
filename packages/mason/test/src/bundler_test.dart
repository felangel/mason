import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

void main() {
  group('Bundler', () {
    group('createBundle', () {
      test('throws if brick does not exist', () {
        final message =
            '''Could not find brick at ${path.join(Directory.current.path, BrickYaml.file)}''';
        expect(
          () => createBundle(Directory.current),
          throwsA(
            isA<BrickNotFoundException>().having(
              (e) => e.message,
              'message',
              message,
            ),
          ),
        );
      });

      test('returns a MasonBundle when brick exists (simple)', () {
        final bundle = createBundle(
          Directory(path.join('..', '..', 'bricks', 'simple')),
        );
        expect(bundle.name, equals('simple'));
        expect(bundle.description, equals('A Simple Static Template'));
        expect(bundle.hooks, isEmpty);
        expect(bundle.files.length, equals(1));
      });

      test('returns a MasonBundle when brick exists (hooks)', () {
        final bundle = createBundle(
          Directory(path.join('..', '..', 'bricks', 'hooks')),
        );
        expect(bundle.name, equals('hooks'));
        expect(bundle.description, equals('A Hooks Example Template'));
        expect(bundle.files.length, equals(1));
        expect(bundle.hooks.length, equals(3));
        final expectedFiles = ['post_gen.dart', 'pre_gen.dart', 'pubspec.yaml'];
        for (var i = 0; i < bundle.hooks.length; i++) {
          final hookFile = bundle.hooks[i];
          expect(hookFile.path, equals(expectedFiles[i]));
        }
      });

      test('returns a MasonBundle when brick exists (plugin)', () {
        final expectedFilePaths = [
          'example/{{#android}}android.dart{{/android}}',
          'example/{{#ios}}ios.dart{{/ios}}',
          'README.md',
          'tests/{{#android}}android_tests.dart{{/android}}',
          'tests/{{#ios}}ios_tests.dart{{/ios}}',
          '{{#android}}android{{/android}}/README.md',
          '{{#android}}build.gradle{{/android}}',
          '{{#ios}}ios{{/ios}}/README.md',
          '{{#ios}}Podfile{{/ios}}',
        ];
        final bundle = createBundle(
          Directory(path.join('..', '..', 'bricks', 'plugin')),
        );
        expect(bundle.name, equals('plugin'));
        expect(bundle.description, equals('An example plugin template'));
        expect(bundle.hooks.length, equals(0));
        expect(bundle.files.length, equals(9));
        for (var i = 0; i < bundle.files.length; i++) {
          expect(bundle.files[i].path, equals(expectedFilePaths[i]));
        }
      });
    });
  });
}
