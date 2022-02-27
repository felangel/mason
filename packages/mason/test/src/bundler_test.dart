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

    group('unpackBundle', () {
      test('unpacks a MasonBundle (simple)', () {
        final tempDir = Directory.systemTemp.createTempSync();
        final bundle = createBundle(
          Directory(path.join('..', '..', 'bricks', 'simple')),
        );
        unpackBundle(bundle, tempDir);
        final yaml = File(path.join(tempDir.path, 'brick.yaml'));
        expect(yaml.existsSync(), isTrue);
        expect(
          yaml.readAsStringSync(),
          equals(
            'name: simple\n'
            'description: A Simple Static Template\n'
            'version: 0.1.0+1\n'
            'environment:\n'
            '  mason: any\n'
            'vars:\n',
          ),
        );
        final file = File(path.join(tempDir.path, '__brick__', 'HELLO.md'));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hello World!'));
      });

      test('unpacks a MasonBundle (hooks)', () {
        final tempDir = Directory.systemTemp.createTempSync();
        final bundle = createBundle(
          Directory(path.join('..', '..', 'bricks', 'hooks')),
        );
        unpackBundle(bundle, tempDir);
        final yaml = File(path.join(tempDir.path, 'brick.yaml'));
        expect(yaml.existsSync(), isTrue);
        expect(
          yaml.readAsStringSync(),
          equals(
            'name: hooks\n'
            'description: A Hooks Example Template\n'
            'version: 0.1.0+1\n'
            'environment:\n'
            '  mason: any\n'
            'vars:\n'
            '  name:\n'
            '    type: string\n'
            '    description: Your name\n'
            '    default: Dash\n'
            '    prompt: "What is your name?"',
          ),
        );
        final file = File(path.join(tempDir.path, '__brick__', 'hooks.md'));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hi {{name}}!'));
        final preGenHookFile = File(
          path.join(tempDir.path, 'hooks', 'pre_gen.dart'),
        );
        expect(preGenHookFile.existsSync(), true);
        expect(
          preGenHookFile.readAsStringSync(),
          equals(
            '''import 'dart:io';import 'package:mason/mason.dart';void run(HookContext context){final file=File('.pre_gen.txt');file.writeAsStringSync('pre_gen: {{name}}');}''',
          ),
        );
        final postGenHookFile = File(
          path.join(tempDir.path, 'hooks', 'post_gen.dart'),
        );
        expect(postGenHookFile.existsSync(), true);
        expect(
          postGenHookFile.readAsStringSync(),
          equals(
            '''import 'dart:io';import 'package:mason/mason.dart';void run(HookContext context){final file=File('.post_gen.txt');file.writeAsStringSync('post_gen: {{name}}');}''',
          ),
        );
        final hookPubspecFile = File(
          path.join(tempDir.path, 'hooks', 'pubspec.yaml'),
        );
        expect(
          hookPubspecFile.readAsStringSync(),
          contains('name: hooks_hooks'),
        );
        expect(hookPubspecFile.existsSync(), true);
      });
    });
  });
}
