import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../bundles/bundles.dart';

void main() {
  group('MasonGenerator', () {
    group('.fromBrickYaml', () {
      test('constructs an instance', () async {
        const name = 'Dash';
        final brickYaml = BrickYaml(
          'hello_world',
          'A Simple Hello World Template',
          path: path.join('..', '..', 'bricks', 'hello_world', 'brick.yaml'),
          vars: const ['name'],
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );
        final file = File(path.join(tempDir.path, 'HELLO.md'));
        expect(fileCount, equals(1));
        expect(file.existsSync(), isTrue);
        expect(
          file.readAsStringSync(),
          equals(
            '# 🧱 $name\n'
            '\n'
            'Hello $name!\n'
            '\n'
            '_made with 💖 by mason_',
          ),
        );
      });

      test('constructs an instance with hooks', () async {
        const name = 'Dash';
        final brickYaml = BrickYaml(
          'hooks',
          'A Hooks Example Template',
          path: path.join('..', '..', 'bricks', 'hooks', 'brick.yaml'),
          vars: const ['name'],
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();

        await generator.hooks.preGen?.run(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );
        await generator.hooks.postGen?.run(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );
        final file = File(path.join(tempDir.path, 'hooks.md'));
        expect(fileCount, equals(1));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hi $name!'));

        final preGenFile = File(path.join(tempDir.path, '.pre_gen.txt'));
        expect(preGenFile.existsSync(), isTrue);
        expect(preGenFile.readAsStringSync(), equals('pre_gen: $name'));

        final postGenFile = File(path.join(tempDir.path, '.post_gen.txt'));
        expect(postGenFile.existsSync(), isTrue);
        expect(postGenFile.readAsStringSync(), equals('post_gen: $name'));
      });
    });

    group('.fromBundle', () {
      test('constructs an instance', () async {
        const name = 'Dash';
        final generator = await MasonGenerator.fromBundle(greetingBundle);
        final tempDir = Directory.systemTemp.createTempSync();

        await generator.hooks.preGen?.run(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );
        await generator.hooks.postGen?.run(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );

        final file = File(path.join(tempDir.path, 'GREETINGS.md'));
        expect(fileCount, equals(1));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hi $name!'));
      });

      test('constructs an instance with hooks', () async {
        const name = 'Dash';
        final generator = await MasonGenerator.fromBundle(hooksBundle);
        final tempDir = Directory.systemTemp.createTempSync();

        await generator.hooks.preGen?.run(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );
        await generator.hooks.postGen?.run(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );

        final file = File(path.join(tempDir.path, 'hooks.md'));
        expect(fileCount, equals(1));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hi $name!'));

        final preGenFile = File(path.join(tempDir.path, '.pre_gen.txt'));
        expect(preGenFile.existsSync(), isTrue);
        expect(preGenFile.readAsStringSync(), equals('pre_gen: $name'));

        final postGenFile = File(path.join(tempDir.path, '.post_gen.txt'));
        expect(postGenFile.existsSync(), isTrue);
        expect(postGenFile.readAsStringSync(), equals('post_gen: $name'));
      });
    });

    group('.fromGitPath', () {
      test('constructs an instance', () async {
        const name = 'Dash';
        final generator = await MasonGenerator.fromGitPath(
          const GitPath(
            'https://github.com/felangel/mason',
            path: 'bricks/greeting',
          ),
        );
        final tempDir = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );
        final file = File(path.join(tempDir.path, 'GREETINGS.md'));
        expect(fileCount, equals(1));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hi $name!'));
      });
    });

    group('generate', () {
      test('generates app_icon from dynamic url', () async {
        const url =
            'https://raw.githubusercontent.com/felangel/mason/master/assets/mason_logo.png';
        final brickYaml = BrickYaml(
          'app_icon',
          'Create an app_icon file from a URL',
          path: path.join('..', '..', 'bricks', 'app_icon', 'brick.yaml'),
          vars: const ['url'],
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'url': url},
        );
        // final file = File(path.join(tempDir.path, path.basename(url)));
        expect(fileCount, equals(1));
        // expect(file.existsSync(), isTrue);
      });
    });
  });
}
