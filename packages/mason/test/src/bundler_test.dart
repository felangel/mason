import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

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
        expect(bundle.version, equals('0.1.0+1'));
        expect(bundle.repository, isNull);
        expect(bundle.readme, isNull);
        expect(bundle.changelog, isNull);
        expect(bundle.license, isNull);
        expect(bundle.hooks, isEmpty);
        expect(bundle.files.length, equals(1));
      });

      test('returns a MasonBundle when brick exists (empty)', () {
        final bundle = createBundle(
          Directory(path.join('test', 'fixtures', 'empty')),
        );
        expect(bundle.name, equals('empty'));
        expect(bundle.description, equals('An empty brick'));
        expect(bundle.version, equals('0.1.0+1'));
        expect(bundle.repository, isNull);
        expect(bundle.readme, isNull);
        expect(bundle.changelog, isNull);
        expect(bundle.license, isNull);
        expect(bundle.hooks, isEmpty);
        expect(bundle.files, isEmpty);
      });

      test('returns a MasonBundle when brick exists (hello)', () {
        final bundle = createBundle(
          Directory(path.join('..', '..', 'bricks', 'hello')),
        );
        Matcher isBundledFile(String path) {
          return isA<MasonBundledFile>()
              .having((b) => b.path, 'path', path)
              .having((b) => b.type, 'type', 'text')
              .having((b) => b.data, 'data', isNotEmpty);
        }

        expect(bundle.name, equals('hello'));
        expect(bundle.description, equals('An example brick.'));
        expect(bundle.version, equals('0.1.0+1'));
        expect(
          bundle.repository,
          equals('https://github.com/felangel/mason/tree/master/bricks/hello'),
        );
        expect(bundle.readme, isBundledFile('README.md'));
        expect(bundle.changelog, isBundledFile('CHANGELOG.md'));
        expect(bundle.license, isBundledFile('LICENSE'));
        expect(bundle.hooks, isEmpty);
        expect(bundle.files.length, equals(1));
      });

      test('returns a MasonBundle when brick exists (hooks)', () {
        final bundle = createBundle(
          Directory(path.join('..', '..', 'bricks', 'hooks')),
        );
        expect(bundle.name, equals('hooks'));
        expect(bundle.description, equals('A Hooks Example Template'));
        expect(bundle.version, equals('0.1.0+1'));
        expect(bundle.repository, isNull);
        expect(bundle.readme, isNull);
        expect(bundle.changelog, isNull);
        expect(bundle.license, isNull);
        expect(bundle.files.length, equals(1));
        expect(bundle.hooks.length, equals(3));
        final expectedFiles = ['post_gen.dart', 'pre_gen.dart', 'pubspec.yaml'];
        for (var i = 0; i < bundle.hooks.length; i++) {
          final hookFile = bundle.hooks[i];
          expect(hookFile.path, equals(expectedFiles[i]));
        }
      });

      test(
          'returns a MasonBundle '
          'when brick exists (hooks w/relative imports)', () {
        final bundle = createBundle(
          Directory(path.join('test', 'fixtures', 'relative_imports')),
        );
        expect(bundle.name, equals('relative_imports'));
        expect(bundle.description, equals('A Test Hook'));
        expect(bundle.version, equals('0.1.0+1'));
        expect(bundle.repository, isNull);
        expect(bundle.readme, isNull);
        expect(bundle.changelog, isNull);
        expect(bundle.license, isNull);
        expect(bundle.files.length, equals(1));
        expect(bundle.hooks.length, equals(4));
        final expectedFiles = [
          'post_gen.dart',
          'pre_gen.dart',
          'pubspec.yaml',
          'src/main.dart',
        ];
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
        expect(bundle.version, equals('0.1.0+1'));
        expect(bundle.repository, isNull);
        expect(bundle.readme, isNull);
        expect(bundle.changelog, isNull);
        expect(bundle.license, isNull);
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

      test('unpacks a MasonBundle (hello)', () {
        final tempDir = Directory.systemTemp.createTempSync();
        final bundle = createBundle(
          Directory(path.join('..', '..', 'bricks', 'hello')),
        );
        unpackBundle(bundle, tempDir);
        final yaml = File(path.join(tempDir.path, 'brick.yaml'));
        expect(yaml.existsSync(), isTrue);
        expect(
          yaml.readAsStringSync(),
          equals(
            'name: hello\n'
            'description: An example brick.\n'
            'version: 0.1.0+1\n'
            'environment:\n'
            '  mason: ">=0.1.0-dev <0.1.0"\n'
            'repository: "https://github.com/felangel/mason/tree/master/bricks/hello"\n'
            'vars:\n'
            '  name:\n'
            '    type: string\n'
            '    description: Your name\n'
            '    default: Dash\n'
            '    prompt: "What is your name?"',
          ),
        );

        final file = File(path.join(tempDir.path, '__brick__', 'HELLO.md'));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hello {{name}}! 👋'));

        final readme = File(path.join(tempDir.path, 'README.md'));
        expect(readme.existsSync(), isTrue);
        expect(
          readme.readAsStringSync(),
          equals(
            '# hello\n'
            '\n'
            'A new brick created with the Mason CLI.\n'
            '\n'
            '_Generated by [mason][1] 🧱_\n'
            '\n'
            '## Getting Started 🚀\n'
            '\n'
            'This is a starting point for a new brick.\n'
            '''A few resources to get you started if this is your first brick template:\n'''
            '\n'
            '- [Official Mason Documentation][2]\n'
            '- [Code generation with Mason Blog][3]\n'
            '- [Very Good Livestream: Felix Angelov Demos Mason][4]\n'
            '\n'
            '[1]: https://github.com/felangel/mason\n'
            '[2]: https://github.com/felangel/mason/tree/master/packages/mason_cli#readme\n'
            '[3]: https://verygood.ventures/blog/code-generation-with-mason\n'
            '[4]: https://youtu.be/G4PTjA6tpTU\n',
          ),
        );

        final changelog = File(path.join(tempDir.path, 'CHANGELOG.md'));
        expect(changelog.existsSync(), isTrue);
        expect(
          changelog.readAsStringSync(),
          equals(
            '# 0.1.0+1\n'
            '\n'
            '- TODO: Describe initial release.\n',
          ),
        );

        final license = File(path.join(tempDir.path, 'LICENSE'));
        expect(license.existsSync(), isTrue);
        expect(
          license.readAsStringSync(),
          equals('TODO: Add your license here.\n'),
        );
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
        expect(preGenHookFile.existsSync(), isTrue);
        expect(
          preGenHookFile.readAsStringSync(),
          equals(
            r'''import 'dart:io';import 'package:mason/mason.dart';void run(HookContext context){final file=File('.pre_gen.txt');file.writeAsStringSync('pre_gen: ${context.vars['name']}');}''',
          ),
        );
        final postGenHookFile = File(
          path.join(tempDir.path, 'hooks', 'post_gen.dart'),
        );
        expect(postGenHookFile.existsSync(), isTrue);
        expect(
          postGenHookFile.readAsStringSync(),
          equals(
            r'''import 'dart:io';import 'package:mason/mason.dart';void run(HookContext context){final file=File('.post_gen.txt');file.writeAsStringSync('post_gen: ${context.vars['name']}');}''',
          ),
        );
        final hookPubspecFile = File(
          path.join(tempDir.path, 'hooks', 'pubspec.yaml'),
        );
        expect(
          hookPubspecFile.readAsStringSync(),
          contains('name: hooks_hooks'),
        );
        expect(hookPubspecFile.existsSync(), isTrue);
      });

      test('unpacks a MasonBundle (hooks w/relative imports)', () {
        final tempDir = Directory.systemTemp.createTempSync();
        final bundle = createBundle(
          Directory(path.join('test', 'fixtures', 'relative_imports')),
        );
        unpackBundle(bundle, tempDir);
        final yaml = File(path.join(tempDir.path, 'brick.yaml'));
        expect(yaml.existsSync(), isTrue);
        expect(
          yaml.readAsStringSync(),
          equals(
            'name: relative_imports\n'
            'description: A Test Hook\n'
            'version: 0.1.0+1\n'
            'environment:\n'
            '  mason: any\n'
            'vars:\n',
          ),
        );
        final file = File(path.join(tempDir.path, '__brick__', '.gitkeep'));
        expect(file.existsSync(), isTrue);
        final preGenHookFile = File(
          path.join(tempDir.path, 'hooks', 'pre_gen.dart'),
        );
        expect(preGenHookFile.existsSync(), isTrue);
        expect(
          preGenHookFile.readAsStringSync(),
          equals(
            '''
import 'package:mason/mason.dart';
import './src/main.dart';

void run(HookContext context) => preGen(context);
''',
          ),
        );
        final postGenHookFile = File(
          path.join(tempDir.path, 'hooks', 'post_gen.dart'),
        );
        expect(postGenHookFile.existsSync(), isTrue);
        expect(
          postGenHookFile.readAsStringSync(),
          equals(
            '''
import 'package:mason/mason.dart';
import './src/main.dart';

void run(HookContext context) => postGen(context);
''',
          ),
        );
        final mainFile = File(
          path.join(tempDir.path, 'hooks', 'src', 'main.dart'),
        );
        expect(mainFile.existsSync(), isTrue);
        expect(
          mainFile.readAsStringSync(),
          equals(
            r'''
import 'dart:io';
import 'package:mason/mason.dart';

void preGen(HookContext context) {
  File('.pre_gen.txt').writeAsStringSync('pre_gen: ${context.vars['name']}');
}

void postGen(HookContext context) {
  File('.post_gen.txt').writeAsStringSync('post_gen: ${context.vars['name']}');
}
''',
          ),
        );
        final hookPubspecFile = File(
          path.join(tempDir.path, 'hooks', 'pubspec.yaml'),
        );
        expect(
          hookPubspecFile.readAsStringSync(),
          contains('name: relative_imports_hooks'),
        );
        expect(hookPubspecFile.existsSync(), isTrue);
      });
    });
  });
}
