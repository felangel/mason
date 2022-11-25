// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../bundles/bundles.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('MasonGenerator', () {
    group('.fromBrick (path)', () {
      test('handles malformed brick', () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final brick = Brick.path(path.join(tempDir.path, 'malformed'));
        File(path.join(tempDir.path, 'malformed', 'brick.yaml'))
          ..createSync(recursive: true)
          ..writeAsStringSync(
            'name: malformed\ndescription: example\nversion: 0.1.0+1',
          );
        final brokenFile = File(
          path.join(tempDir.path, 'malformed', '__brick__', 'locked.txt'),
        )
          ..createSync(recursive: true)
          ..writeAsStringSync('secret');
        await Process.run('chmod', ['000', brokenFile.path]);

        final generator = await MasonGenerator.fromBrick(brick);
        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
        );

        expect(files, isEmpty);
      });

      test('constructs an instance (empty)', () async {
        final brick = Brick.path(path.join('test', 'fixtures', 'empty'));
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();
        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
        );
        expect(files, isEmpty);
      });

      test('constructs an instance (hello_world)', () async {
        const name = 'Dash';
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'hello_world'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );

        final file = File(path.join(tempDir.path, 'HELLO.md'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
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
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'todos'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files = await generator.generate(
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

        expect(files.length, equals(13));
        expect(
          files.every((f) => f.status == GeneratedFileStatus.created),
          isTrue,
        );
      });

      test('constructs an instance (loops)', () async {
        final brick = Brick.path(
          path.join('test', 'bricks', 'loop'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{
            'values': ['development', 'staging', 'production']
          },
        );

        expect(files.length, equals(3));
        expect(
          files.every(
            (element) => element.status == GeneratedFileStatus.created,
          ),
          isTrue,
        );

        final development =
            File(path.join(tempDir.path, 'main_development.txt'));
        final staging = File(path.join(tempDir.path, 'main_staging.txt'));
        final production = File(path.join(tempDir.path, 'main_production.txt'));

        expect(development.existsSync(), isTrue);
        expect(staging.existsSync(), isTrue);
        expect(production.existsSync(), isTrue);

        expect(development.readAsStringSync(), equals('DEVELOPMENT'));
        expect(staging.readAsStringSync(), equals('STAGING'));
        expect(production.readAsStringSync(), equals('PRODUCTION'));
      });

      test('constructs an instance (loops stress test)', () async {
        const fileCount = 1000;
        final brick = Brick.path(
          path.join('test', 'bricks', 'loop'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();
        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{
            'values': List.generate(fileCount, (index) => '$index'),
          },
        );

        expect(files.length, equals(fileCount));
        expect(
          files.every(
            (element) => element.status == GeneratedFileStatus.created,
          ),
          isTrue,
        );
      });

      test('constructs an instance with hooks', () async {
        const name = 'Dash';
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'hooks'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        await generator.hooks.preGen(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );
        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );
        await generator.hooks.postGen(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );

        final file = File(path.join(tempDir.path, 'hooks.md'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hi $name!'));

        final preGenFile = File(path.join(tempDir.path, '.pre_gen.txt'));
        expect(preGenFile.existsSync(), isTrue);
        expect(preGenFile.readAsStringSync(), equals('pre_gen: $name'));

        final postGenFile = File(path.join(tempDir.path, '.post_gen.txt'));
        expect(postGenFile.existsSync(), isTrue);
        expect(postGenFile.readAsStringSync(), equals('post_gen: $name'));
      });

      test('constructs an instance with hooks w/relative imports', () async {
        const name = 'Dash';
        final brick = Brick.path(
          path.join('test', 'fixtures', 'relative_imports'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        await generator.hooks.preGen(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );
        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );
        await generator.hooks.postGen(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );

        final file = File(path.join(tempDir.path, '.gitkeep'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);

        final preGenFile = File(path.join(tempDir.path, '.pre_gen.txt'));
        expect(preGenFile.existsSync(), isTrue);
        expect(preGenFile.readAsStringSync(), equals('pre_gen: $name'));

        final postGenFile = File(path.join(tempDir.path, '.post_gen.txt'));
        expect(postGenFile.existsSync(), isTrue);
        expect(postGenFile.readAsStringSync(), equals('post_gen: $name'));
      });

      test('constructs an instance with random_color', () async {
        const name = 'Dash';
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'random_color'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();
        final updatedVars = <Map<String, dynamic>>[];

        await generator.hooks.preGen(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
          onVarsChanged: updatedVars.add,
        );

        expect(updatedVars.length, equals(1));
        expect(updatedVars.first['name'], equals(name));
        expect(updatedVars.first['favorite_color'], isNotEmpty);

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );

        await generator.hooks.postGen(
          vars: updatedVars.first,
          workingDirectory: tempDir.path,
        );

        final file = File(path.join(tempDir.path, 'color.md'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);
        expect(
          file.readAsStringSync(),
          contains('Hi $name!\nYour favorite color is'),
        );
      });

      test(
          'constructs an instance multiple times '
          '(identical) (hello_world)', () async {
        const name = 'Dash';
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'hello_world'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();
        final logger = MockLogger();

        final files1 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
          logger: logger,
        );

        final file1 = File(path.join(tempDir.path, 'HELLO.md'));
        final generatedFile1 = files1.first;
        expect(files1.length, equals(1));
        expect(generatedFile1.status, equals(GeneratedFileStatus.created));
        expect(generatedFile1.path, equals(file1.path));
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

        final files2 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
          logger: logger,
        );

        final file2 = File(path.join(tempDir.path, 'HELLO.md'));
        final generatedFile2 = files2.first;
        expect(files2.length, equals(1));
        expect(generatedFile2.status, equals(GeneratedFileStatus.identical));
        expect(generatedFile2.path, equals(file1.path));
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
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'hello_world'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();
        final logger = MockLogger();

        final files1 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
          logger: logger,
        );

        final file1 = File(path.join(tempDir.path, 'HELLO.md'));
        final generatedFile1 = files1.first;
        expect(files1.length, equals(1));
        expect(generatedFile1.status, equals(GeneratedFileStatus.created));
        expect(generatedFile1.path, equals(file1.path));
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

        final files2 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': otherName},
          fileConflictResolution: FileConflictResolution.skip,
          logger: logger,
        );

        final file2 = File(path.join(tempDir.path, 'HELLO.md'));
        final generatedFile2 = files2.first;
        expect(files2.length, equals(1));
        expect(generatedFile2.status, equals(GeneratedFileStatus.skipped));
        expect(generatedFile2.path, equals(file2.path));
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
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'hello_world'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();
        final logger = MockLogger();

        final files1 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
          logger: logger,
        );

        final file1 = File(path.join(tempDir.path, 'HELLO.md'));
        final generatedFile1 = files1.first;
        expect(files1.length, equals(1));
        expect(generatedFile1.status, equals(GeneratedFileStatus.created));
        expect(generatedFile1.path, equals(file1.path));
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

        final files2 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': otherName},
          fileConflictResolution: FileConflictResolution.append,
          logger: logger,
        );

        final file2 = File(path.join(tempDir.path, 'HELLO.md'));
        final generatedFile2 = files2.first;
        expect(files2.length, equals(1));
        expect(generatedFile2.status, equals(GeneratedFileStatus.appended));
        expect(generatedFile2.path, equals(file2.path));
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
          'times w/prompt - Y (documentation)', () async {
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'documentation'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final logger = MockLogger();
        final files1 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{
            'name': 'name1',
            'description': 'description1',
            'author': 'author1',
          },
          logger: logger,
        );

        expect(files1.length, equals(4));
        expect(
          files1.every((f) => f.status == GeneratedFileStatus.created),
          isTrue,
        );
        verifyNever(() => logger.prompt(any()));

        when(() => logger.prompt(any())).thenReturn('Y');

        final files2 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{
            'name': 'name2',
            'description': 'description2',
            'author': 'author2',
          },
          logger: logger,
        );

        expect(files2.length, equals(4));
        verify(() => logger.prompt(any())).called(1);
      });

      test(
          'constructs an instance multiple '
          'times w/prompt - Y (hello_world)', () async {
        const name = 'Dash';
        const otherName = 'Other Dash';
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'hello_world'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files1 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );

        final file1 = File(path.join(tempDir.path, 'HELLO.md'));
        final generatedFile1 = files1.first;
        expect(files1.length, equals(1));
        expect(generatedFile1.status, equals(GeneratedFileStatus.created));
        expect(generatedFile1.path, equals(file1.path));
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

        final files2 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': otherName},
          fileConflictResolution: FileConflictResolution.prompt,
          logger: logger,
        );

        final file2 = File(path.join(tempDir.path, 'HELLO.md'));
        final generatedFile2 = files2.first;
        expect(files2.length, equals(1));
        expect(generatedFile2.status, equals(GeneratedFileStatus.overwritten));
        expect(generatedFile2.path, equals(file2.path));
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
        verify(() => logger.prompt(any())).called(1);
      });

      test(
          'constructs an instance multiple times '
          'and overwrites by default', () async {
        const name = 'Dash';
        const otherName = 'Other Dash';
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'hello_world'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files1 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );

        final file1 = File(path.join(tempDir.path, 'HELLO.md'));
        final generatedFile1 = files1.first;
        expect(files1.length, equals(1));
        expect(generatedFile1.status, equals(GeneratedFileStatus.created));
        expect(generatedFile1.path, equals(file1.path));
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

        final files2 = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': otherName},
        );

        final file2 = File(path.join(tempDir.path, 'HELLO.md'));
        final generatedFile2 = files2.first;
        expect(files2.length, equals(1));
        expect(generatedFile2.status, equals(GeneratedFileStatus.overwritten));
        expect(generatedFile2.path, equals(file2.path));
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
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'hello_world'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
          fileConflictResolution: FileConflictResolution.skip,
        );

        final file = File(path.join(tempDir.path, 'HELLO.md'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
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

        await generator.hooks.preGen(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );

        await generator.hooks.postGen(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );

        final file = File(path.join(tempDir.path, 'GREETINGS.md'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hi $name!'));
      });

      test('constructs an instance with hooks', () async {
        const name = 'Dash';
        final generator = await MasonGenerator.fromBundle(hooksBundle);
        final tempDir = Directory.systemTemp.createTempSync();

        await generator.hooks.preGen(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );

        await generator.hooks.postGen(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );

        final file = File(path.join(tempDir.path, 'hooks.md'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hi $name!'));

        final preGenFile = File(path.join(tempDir.path, '.pre_gen.txt'));
        expect(preGenFile.existsSync(), isTrue);
        expect(preGenFile.readAsStringSync(), equals('pre_gen: $name'));

        final postGenFile = File(path.join(tempDir.path, '.post_gen.txt'));
        expect(postGenFile.existsSync(), isTrue);
        expect(postGenFile.readAsStringSync(), equals('post_gen: $name'));
      });

      test('constructs an instance with hooks w/relative imports', () async {
        const name = 'Dash';
        final generator = await MasonGenerator.fromBundle(
          relativeImportsBundle,
        );
        final tempDir = Directory.systemTemp.createTempSync();

        await generator.hooks.preGen(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );

        await generator.hooks.postGen(
          vars: <String, dynamic>{'name': name},
          workingDirectory: tempDir.path,
        );

        final file = File(path.join(tempDir.path, '.gitkeep'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);

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

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{},
        );

        final file = File(path.join(tempDir.path, 'image.png'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);
      });
    });

    group('.fromBrick (git)', () {
      test('constructs an instance', () async {
        const name = 'Dash';
        final brick = Brick.git(
          const GitPath(
            'https://github.com/felangel/mason',
            path: 'bricks/greeting',
          ),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );

        final file = File(path.join(tempDir.path, 'GREETINGS.md'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hi $name!'));
      });
    });

    group('.fromBrick (version)', () {
      test('constructs an instance (exact version)', () async {
        const name = 'Dash';
        final brick = Brick.version(name: 'greeting', version: '0.1.0+1');
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );

        final file = File(path.join(tempDir.path, 'GREETINGS.md'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hi $name!'));
      });

      test('constructs an instance (version constraint)', () async {
        const name = 'Dash';
        final brick = Brick.version(name: 'greeting', version: '^0.1.0');
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );

        final file = File(path.join(tempDir.path, 'GREETINGS.md'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hi $name!'));
      });

      test('constructs an instance (version range)', () async {
        const name = 'Dash';
        final brick = Brick.version(
          name: 'greeting',
          version: '>=0.1.0 <0.2.0',
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );

        final file = File(path.join(tempDir.path, 'GREETINGS.md'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hi $name!'));
      });

      test('constructs an instance (any version)', () async {
        const name = 'Dash';
        final brick = Brick.version(name: 'greeting', version: 'any');
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );

        final file = File(path.join(tempDir.path, 'GREETINGS.md'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('Hi $name!'));
      });
    });

    group('generate', () {
      test('generates app_icon from remote url', () async {
        const url =
            'https://raw.githubusercontent.com/felangel/mason/master/assets/mason_logo.png';
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'app_icon'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'url': url},
        );

        final file = File(path.join(tempDir.path, path.basename(url)));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);
      });

      test('generates app_icon from local url', () async {
        final url = path.join('..', '..', 'assets', 'mason_logo.png');
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'app_icon'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'url': url},
        );

        final file = File(path.join(tempDir.path, path.basename(url)));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);
      });

      test('generates photos', () async {
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'photos'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{},
        );

        final file = File(path.join(tempDir.path, 'image.png'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
        expect(file.existsSync(), isTrue);
      });

      test('generates bio', () async {
        final brick = Brick.path(
          path.join('..', '..', 'bricks', 'bio'),
        );
        final generator = await MasonGenerator.fromBrick(brick);
        final tempDir = Directory.systemTemp.createTempSync();

        final files = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{
            'name': 'Dash',
            'age': 42,
            'isDeveloper': true,
          },
        );

        final file = File(path.join(tempDir.path, 'ABOUT.md'));
        final generatedFile = files.first;
        expect(files.length, equals(1));
        expect(generatedFile.status, equals(GeneratedFileStatus.created));
        expect(generatedFile.path, equals(file.path));
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
  });
}
