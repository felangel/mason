// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:mason/mason.dart';
import 'package:mason/src/generator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../bundles/bundles.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('MasonGenerator', () {
    group('.fromBrickYaml', () {
      test('handles malformed brick', () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final brickYaml = BrickYaml(
          name: 'malformed',
          description: 'A Malformed Template',
          version: '1.0.0',
          path: path.join(tempDir.path, 'malformed', 'brick.yaml'),
        );
        File(path.join(tempDir.path, 'malformed', 'brick.yaml'))
          ..createSync(recursive: true)
          ..writeAsStringSync('name: malformed\ndescription: example');
        final brokenFile = File(
          path.join(tempDir.path, 'malformed', '__brick__', 'locked.txt'),
        )
          ..createSync(recursive: true)
          ..writeAsStringSync('secret');
        await Process.run('chmod', ['000', brokenFile.path]);
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{},
        );
        expect(fileCount, equals(0));
      });

      test('constructs an instance (hello_world)', () async {
        const name = 'Dash';
        final brickYaml = BrickYaml(
          name: 'hello_world',
          description: 'A Simple Hello World Template',
          version: '1.0.0',
          path: path.join('..', '..', 'bricks', 'hello_world', 'brick.yaml'),
          vars: const {'name': BrickVariableProperties.string()},
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

      test('constructs an instance (todos)', () async {
        final brickYaml = BrickYaml(
          name: 'todos',
          description: 'A Todos Template',
          version: '1.0.0',
          path: path.join('..', '..', 'bricks', 'todos', 'brick.yaml'),
          vars: const {'todos': BrickVariableProperties.string()},
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{
            'todos': [
              {'todo': 'Eat', 'done': true},
              {'todo': 'Code', 'done': true},
              {'todo': 'Sleep', 'done': false}
            ],
            'developers': [
              {'name': 'Alex'},
              {'name': 'Sam'},
              {'name': 'Jen'}
            ]
          },
        );
        expect(fileCount, equals(13));
      });

      test('constructs an instance with hooks', () async {
        const name = 'Dash';
        final brickYaml = BrickYaml(
          name: 'hooks',
          description: 'A Hooks Example Template',
          version: '1.0.0',
          path: path.join('..', '..', 'bricks', 'hooks', 'brick.yaml'),
          vars: const {'name': BrickVariableProperties.string()},
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

      test(
          'constructs an instance multiple times '
          '(identical) (hello_world)', () async {
        const name = 'Dash';
        final brickYaml = BrickYaml(
          name: 'hello_world',
          description: 'A Simple Hello World Template',
          version: '1.0.0',
          path: path.join('..', '..', 'bricks', 'hello_world', 'brick.yaml'),
          vars: const {'name': BrickVariableProperties.string()},
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();
        final logger = MockLogger();

        final fileCount1 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
          logger: logger,
        );
        final file1 = File(path.join(tempDir.path, 'HELLO.md'));
        expect(fileCount1, equals(1));
        expect(file1.existsSync(), isTrue);
        expect(
          file1.readAsStringSync(),
          equals(
            '# 🧱 $name\n'
            '\n'
            'Hello $name!\n'
            '\n'
            '_made with 💖 by mason_',
          ),
        );
        verify(() => logger.delayed(any(that: contains('(new)')))).called(1);
        verifyNever(
          () => logger.delayed(any(that: contains('(identical)'))),
        );

        final fileCount2 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
          logger: logger,
        );
        final file2 = File(path.join(tempDir.path, 'HELLO.md'));
        expect(fileCount2, equals(1));
        expect(file2.existsSync(), isTrue);
        expect(
          file2.readAsStringSync(),
          equals(
            '# 🧱 $name\n'
            '\n'
            'Hello $name!\n'
            '\n'
            '_made with 💖 by mason_',
          ),
        );
        verify(
          () => logger.delayed(any(that: contains('(identical)'))),
        ).called(1);
        verifyNever(() => logger.delayed(any(that: contains('(new)'))));
      });

      test(
          'constructs an instance multiple '
          'times w/skip (hello_world)', () async {
        const name = 'Dash';
        const otherName = 'Other Dash';
        final brickYaml = BrickYaml(
          name: 'hello_world',
          description: 'A Simple Hello World Template',
          version: '1.0.0',
          path: path.join('..', '..', 'bricks', 'hello_world', 'brick.yaml'),
          vars: const {'name': BrickVariableProperties.string()},
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();
        final logger = MockLogger();

        final fileCount1 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
          logger: logger,
        );
        final file1 = File(path.join(tempDir.path, 'HELLO.md'));
        expect(fileCount1, equals(1));
        expect(file1.existsSync(), isTrue);
        expect(
          file1.readAsStringSync(),
          equals(
            '# 🧱 $name\n'
            '\n'
            'Hello $name!\n'
            '\n'
            '_made with 💖 by mason_',
          ),
        );
        verify(() => logger.delayed(any(that: contains('(new)')))).called(1);
        verifyNever(() => logger.delayed(any(that: contains('(skip)'))));

        final fileCount2 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': otherName},
          fileConflictResolution: FileConflictResolution.skip,
          logger: logger,
        );
        final file2 = File(path.join(tempDir.path, 'HELLO.md'));
        expect(fileCount2, equals(1));
        expect(file2.existsSync(), isTrue);
        expect(
          file2.readAsStringSync(),
          equals(
            '# 🧱 $name\n'
            '\n'
            'Hello $name!\n'
            '\n'
            '_made with 💖 by mason_',
          ),
        );
        verify(() => logger.delayed(any(that: contains('(skip)')))).called(1);
        verifyNever(() => logger.delayed(any(that: contains('(new)'))));
      });

      test(
          'constructs an instance multiple '
          'times w/append (hello_world)', () async {
        const name = 'Dash';
        const otherName = 'Other Dash';
        final brickYaml = BrickYaml(
          name: 'hello_world',
          description: 'A Simple Hello World Template',
          version: '1.0.0',
          path: path.join('..', '..', 'bricks', 'hello_world', 'brick.yaml'),
          vars: const {'name': BrickVariableProperties.string()},
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();
        final logger = MockLogger();
        final fileCount1 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
          logger: logger,
        );
        final file1 = File(path.join(tempDir.path, 'HELLO.md'));
        expect(fileCount1, equals(1));
        expect(file1.existsSync(), isTrue);
        expect(
          file1.readAsStringSync(),
          equals(
            '# 🧱 $name\n'
            '\n'
            'Hello $name!\n'
            '\n'
            '_made with 💖 by mason_',
          ),
        );

        final fileCount2 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': otherName},
          fileConflictResolution: FileConflictResolution.append,
          logger: logger,
        );
        final file2 = File(path.join(tempDir.path, 'HELLO.md'));
        expect(fileCount2, equals(1));
        expect(file2.existsSync(), isTrue);
        expect(
          file2.readAsStringSync(),
          equals(
            '# 🧱 $name\n'
            '\n'
            'Hello $name!\n'
            '\n'
            '_made with 💖 by mason_'
            '# 🧱 $otherName\n'
            '\n'
            'Hello $otherName!\n'
            '\n'
            '_made with 💖 by mason_',
          ),
        );
      });

      test(
          'constructs an instance multiple '
          'times w/prompt - Y (hello_world)', () async {
        const name = 'Dash';
        const otherName = 'Other Dash';
        final brickYaml = BrickYaml(
          name: 'hello_world',
          description: 'A Simple Hello World Template',
          version: '1.0.0',
          path: path.join('..', '..', 'bricks', 'hello_world', 'brick.yaml'),
          vars: const {'name': BrickVariableProperties.string()},
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();

        final fileCount1 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );
        final file1 = File(path.join(tempDir.path, 'HELLO.md'));
        expect(fileCount1, equals(1));
        expect(file1.existsSync(), isTrue);
        expect(
          file1.readAsStringSync(),
          equals(
            '# 🧱 $name\n'
            '\n'
            'Hello $name!\n'
            '\n'
            '_made with 💖 by mason_',
          ),
        );

        final logger = MockLogger();
        when(() => logger.prompt(any())).thenReturn('Y');
        final fileCount2 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': otherName},
          fileConflictResolution: FileConflictResolution.prompt,
          logger: logger,
        );
        final file2 = File(path.join(tempDir.path, 'HELLO.md'));
        expect(fileCount2, equals(1));
        expect(file2.existsSync(), isTrue);
        expect(
          file2.readAsStringSync(),
          equals(
            '# 🧱 $otherName\n'
            '\n'
            'Hello $otherName!\n'
            '\n'
            '_made with 💖 by mason_',
          ),
        );
      });

      test(
          'constructs an instance multiple times '
          'and overwrites by default', () async {
        const name = 'Dash';
        const otherName = 'Other Dash';
        final brickYaml = BrickYaml(
          name: 'hello_world',
          description: 'A Simple Hello World Template',
          version: '1.0.0',
          path: path.join('..', '..', 'bricks', 'hello_world', 'brick.yaml'),
          vars: const {'name': BrickVariableProperties.string()},
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();

        final fileCount1 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );
        final file1 = File(path.join(tempDir.path, 'HELLO.md'));
        expect(fileCount1, equals(1));
        expect(file1.existsSync(), isTrue);
        expect(
          file1.readAsStringSync(),
          equals(
            '# 🧱 $name\n'
            '\n'
            'Hello $name!\n'
            '\n'
            '_made with 💖 by mason_',
          ),
        );

        final fileCount2 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': otherName},
        );
        final file2 = File(path.join(tempDir.path, 'HELLO.md'));
        expect(fileCount2, equals(1));
        expect(file2.existsSync(), isTrue);
        expect(
          file2.readAsStringSync(),
          equals(
            '# 🧱 $otherName\n'
            '\n'
            'Hello $otherName!\n'
            '\n'
            '_made with 💖 by mason_',
          ),
        );
      });

      test('constructs an instance w/skip and no conflicts (hello_world)',
          () async {
        const name = 'Dash';
        final brickYaml = BrickYaml(
          name: 'hello_world',
          description: 'A Simple Hello World Template',
          version: '1.0.0',
          path: path.join('..', '..', 'bricks', 'hello_world', 'brick.yaml'),
          vars: const {'name': BrickVariableProperties.string()},
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
          fileConflictResolution: FileConflictResolution.skip,
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

      test('constructs an instance (photos)', () async {
        final generator = await MasonGenerator.fromBundle(photosBundle);
        final tempDir = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{},
        );
        final file = File(path.join(tempDir.path, 'image.png'));
        expect(fileCount, equals(1));
        expect(file.existsSync(), isTrue);
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
      test('generates app_icon from remote url', () async {
        const url =
            'https://raw.githubusercontent.com/felangel/mason/master/assets/mason_logo.png';
        final brickYaml = BrickYaml(
          name: 'app_icon',
          description: 'Create an app_icon file from a URL',
          version: '1.0.0',
          path: path.join('..', '..', 'bricks', 'app_icon', 'brick.yaml'),
          vars: const {'url': BrickVariableProperties.string()},
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'url': url},
        );
        final file = File(path.join(tempDir.path, path.basename(url)));
        expect(fileCount, equals(1));
        expect(file.existsSync(), isTrue);
      });

      test('generates app_icon from local url', () async {
        final url = path.join('..', '..', 'assets', 'mason_logo.png');
        final brickYaml = BrickYaml(
          name: 'app_icon',
          description: 'Create an app_icon file from a URL',
          version: '1.0.0',
          path: path.join('..', '..', 'bricks', 'app_icon', 'brick.yaml'),
          vars: const {'url': BrickVariableProperties.string()},
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'url': url},
        );
        final file = File(path.join(tempDir.path, path.basename(url)));
        expect(fileCount, equals(1));
        expect(file.existsSync(), isTrue);
      });

      test('generates photos', () async {
        final brickYaml = BrickYaml(
          name: 'photos',
          description: 'A Photos Example Template',
          version: '1.0.0',
          path: path.join('..', '..', 'bricks', 'photos', 'brick.yaml'),
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{},
        );
        final file = File(path.join(tempDir.path, 'image.png'));
        expect(fileCount, equals(1));
        expect(file.existsSync(), isTrue);
      });

      test('generates bio', () async {
        final brickYaml = BrickYaml(
          name: 'bio',
          description: 'A Bio Template',
          version: '1.0.0',
          path: path.join('..', '..', 'bricks', 'bio', 'brick.yaml'),
          vars: const {
            'name': BrickVariableProperties.string(),
            'age': BrickVariableProperties.number(),
            'isDeveloper': BrickVariableProperties.boolean(),
          },
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{
            'name': 'Dash',
            'age': 42,
            'isDeveloper': true,
          },
        );
        final file = File(path.join(tempDir.path, 'ABOUT.md'));
        expect(fileCount, equals(1));
        expect(file.existsSync(), isTrue);
      });
    });

    group('compareTo', () {
      test('returns 0 when generators are the same type', () async {
        final generatorA = await MasonGenerator.fromBundle(greetingBundle);
        final generatorB = await MasonGenerator.fromBundle(greetingBundle);
        expect(generatorA.compareTo(generatorB), equals(0));
      });

      test('returns -1 when generators are different types', () async {
        final generatorA = await MasonGenerator.fromBundle(greetingBundle);
        final generatorB = await MasonGenerator.fromBundle(hooksBundle);
        expect(generatorA.compareTo(generatorB), equals(-1));
      });

      test('returns 1 when generators are different types', () async {
        final generatorA = await MasonGenerator.fromBundle(greetingBundle);
        final generatorB = await MasonGenerator.fromBundle(hooksBundle);
        expect(generatorB.compareTo(generatorA), equals(1));
      });
    });

    group('toString', () {
      test('returns correct string', () async {
        final generator = await MasonGenerator.fromBundle(greetingBundle);
        expect(
          generator.toString(),
          equals('[${generator.id}: ${generator.description}]'),
        );
      });
    });

    group('TemplateFile', () {
      group('runSubstitution', () {
        test('handles malformed content', () {
          final tempDir = Directory.systemTemp.createTempSync();
          final bytes = [0x80, 0x00];
          final template = TemplateFile.fromBytes(
            path.join(tempDir.path, 'malformed.txt'),
            bytes,
          );
          final set = template.runSubstitution(<String, dynamic>{}, {});
          expect(set.length, equals(1));
          expect(set.first.content, equals(bytes));
        });
      });
    });

    group('ScriptFile', () {
      group('runSubstitution', () {
        test('handles malformed content', () {
          final tempDir = Directory.systemTemp.createTempSync();
          final bytes = [0x80, 0x00];
          final template = ScriptFile.fromBytes(
            path.join(tempDir.path, 'malformed.txt'),
            bytes,
          );
          final file = template.runSubstitution(<String, dynamic>{});
          expect(file.content, equals(bytes));
        });
      });
    });
  });
}
