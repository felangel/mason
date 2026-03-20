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
        expect(bundle.publishTo, isNull);
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
        expect(bundle.publishTo, isNull);
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
        expect(bundle.version, equals('0.1.0+2'));
        expect(
          bundle.repository,
          equals('https://github.com/felangel/mason/tree/master/bricks/hello'),
        );
        expect(bundle.publishTo, isNull);
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
        expect(bundle.publishTo, isNull);
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
        expect(bundle.publishTo, isNull);
        expect(bundle.readme, isNull);
        expect(bundle.changelog, isNull);
        expect(bundle.license, isNull);
        expect(bundle.files.length, equals(1));
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
        expect(bundle.hooks.length, equals(4));
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
        expect(bundle.publishTo, isNull);
        expect(bundle.readme, isNull);
        expect(bundle.changelog, isNull);
        expect(bundle.license, isNull);
        expect(bundle.hooks.length, equals(0));
        expect(bundle.files.length, equals(9));
        for (var i = 0; i < bundle.files.length; i++) {
          expect(bundle.files[i].path, equals(expectedFilePaths[i]));
        }
      });

      test('returns a MasonBundle when brick exists (custom_registry)', () {
        final bundle = createBundle(
          Directory(path.join('test', 'bricks', 'custom_registry')),
        );
        expect(bundle.name, equals('custom_registry'));
        expect(
          bundle.description,
          equals(
            'A Simple Template that should be published to a custom registry',
          ),
        );
        expect(bundle.version, equals('0.1.0+1'));
        expect(bundle.repository, isNull);
        expect(bundle.publishTo, equals('https://custom.brickhub.dev'));
        expect(bundle.readme, isNull);
        expect(bundle.changelog, isNull);
        expect(bundle.license, isNull);
        expect(bundle.hooks, isEmpty);
        expect(bundle.files, isEmpty);
      });

      test('returns a MasonBundle when brick exists (no_registry)', () {
        final bundle = createBundle(
          Directory(path.join('test', 'bricks', 'no_registry')),
        );
        expect(bundle.name, equals('no_registry'));
        expect(
          bundle.description,
          equals('A Simple Template that cannot be published'),
        );
        expect(bundle.version, equals('0.1.0+1'));
        expect(bundle.repository, isNull);
        expect(bundle.publishTo, equals('none'));
        expect(bundle.readme, isNull);
        expect(bundle.changelog, isNull);
        expect(bundle.license, isNull);
        expect(bundle.hooks, isEmpty);
        expect(bundle.files, isEmpty);
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
          yaml.readAsNormalizedStringSync(),
          equals(
            'name: hello\n'
            'description: An example brick.\n'
            'version: 0.1.0+2\n'
            'environment:\n'
            '  mason: ^$packageVersion\n'
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
          readme.readAsNormalizedStringSync(),
          equals('# hello\n'
              '\n'
              'A hello world brick created with the Mason CLI.\n'
              '\n'
              '_Generated by [mason][1] 🧱_\n'
              '\n'
              '[1]: https://github.com/felangel/mason\n'),
        );

        final changelog = File(path.join(tempDir.path, 'CHANGELOG.md'));
        expect(changelog.existsSync(), isTrue);
        expect(
          changelog.readAsNormalizedStringSync(),
          equals(
            '# 0.1.0+2\n'
            '\n'
            '- chore: upgrade to `mason ^0.1.0`\n'
            '\n'
            '# 0.1.0+1\n'
            '\n'
            '- chore: initial release\n',
          ),
        );

        final license = File(path.join(tempDir.path, 'LICENSE'));
        expect(license.existsSync(), isTrue);
        expect(
          license.readAsNormalizedStringSync(),
          equals(
            'The MIT License (MIT)\n'
            'Copyright (c) 2024 Felix Angelov\n'
            '\n'
            'Permission is hereby granted, free of charge, to any person\n'
            'obtaining a copy of this software and associated documentation\n'
            '''files (the "Software"), to deal in the Software without restriction,\n'''
            '''including without limitation the rights to use, copy, modify, merge,\n'''
            '''publish, distribute, sublicense, and/or sell copies of the Software,\n'''
            '''and to permit persons to whom the Software is furnished to do so,\n'''
            'subject to the following conditions:\n'
            '\n'
            '''The above copyright notice and this permission notice shall be included\n'''
            'in all copies or substantial portions of the Software.\n'
            '\n'
            'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,\n'
            '''EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF\n'''
            '''MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.\n'''
            '''IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,\n'''
            '''DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR\n'''
            '''OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE\n'''
            'USE OR OTHER DEALINGS IN THE SOFTWARE.',
          ),
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
          preGenHookFile.readAsNormalizedStringSync(),
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
          postGenHookFile.readAsNormalizedStringSync(),
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
          mainFile.readAsNormalizedStringSync(),
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

      test('unpacks a MasonBundle (custom_registry)', () {
        final tempDir = Directory.systemTemp.createTempSync();
        final bundle = createBundle(
          Directory(path.join('test', 'bricks', 'custom_registry')),
        );
        unpackBundle(bundle, tempDir);
        final yaml = File(path.join(tempDir.path, 'brick.yaml'));
        expect(yaml.existsSync(), isTrue);
        expect(
          yaml.readAsStringSync(),
          equals(
            'name: custom_registry\n'
            '''description: A Simple Template that should be published to a custom registry\n'''
            'version: 0.1.0+1\n'
            'environment:\n'
            '  mason: any\n'
            'publish_to: "https://custom.brickhub.dev"\n'
            'vars:\n',
          ),
        );
      });

      test('unpacks a MasonBundle (no_registry)', () {
        final tempDir = Directory.systemTemp.createTempSync();
        final bundle = createBundle(
          Directory(path.join('test', 'bricks', 'no_registry')),
        );
        unpackBundle(bundle, tempDir);
        final yaml = File(path.join(tempDir.path, 'brick.yaml'));
        expect(yaml.existsSync(), isTrue);
        expect(
          yaml.readAsStringSync(),
          equals(
            'name: no_registry\n'
            'description: A Simple Template that cannot be published\n'
            'version: 0.1.0+1\n'
            'environment:\n'
            '  mason: any\n'
            'publish_to: none\n'
            'vars:\n',
          ),
        );
      });
    });
  });
}

extension on File {
  String readAsNormalizedStringSync() {
    return readAsStringSync().replaceAll('\r', '');
  }
}
