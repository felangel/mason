// ignore_for_file: no_adjacent_strings_in_list
import 'dart:convert';

import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/command_runner.dart';
import 'package:mason_cli/src/version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

class FakeProcessResult extends Fake implements ProcessResult {}

void main() {
  final cwd = Directory.current;

  group('mason make', () {
    late Logger logger;
    late MasonCommandRunner commandRunner;
    late PubUpdater pubUpdater;

    setUpAll(() async {
      pubUpdater = MockPubUpdater();
      logger = MockLogger();

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);
      when(
        () => pubUpdater.update(packageName: packageName),
      ).thenAnswer((_) => Future.value(FakeProcessResult()));
      await MasonCommandRunner(pubUpdater: pubUpdater).run(['cache', 'clear']);
    });

    setUp(() async {
      setUpTestingEnvironment(cwd, suffix: '.make');
      File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  app_icon:
    path: ../../../../../bricks/app_icon
  documentation:
    path: ../../../../../bricks/documentation
  greeting:
    path: ../../../../../bricks/greeting
  hello_world:
    path: ../../../../../bricks/hello_world
  hooks:
    path: ../../../../../bricks/hooks
  plugin:
    path: ../../../../../bricks/plugin
  simple:
    path: ../../../../../bricks/simple
  todos:
    path: ../../../../../bricks/todos
  widget:
    path: ../../../../../bricks/widget
''',
      );
      final bricksPath = path.join('..', '..', '..', '..', '..', 'bricks');
      final appIconPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'app_icon'),
      );
      final docPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'documentation'),
      );
      final greetingPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'greeting'),
      );
      final helloWorldPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'hello_world'),
      );
      final hooksPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'hooks'),
      );
      final pluginPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'plugin'),
      );
      final simplePath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'simple'),
      );
      final todosPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'todos'),
      );
      final widgetPath = path.canonicalize(
        path.join(Directory.current.path, bricksPath, 'widget'),
      );
      File(path.join(Directory.current.path, '.mason', 'bricks.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          json.encode({
            '''app_icon_0e78d754325c0a6b74c6245089fa310fd32641cf1b9e1c30ce391c07a83dfcb0''':
                appIconPath,
            '''documentation_227871e1f882f1e60fbc26adaf0d5ea0f03616b24c54ce4ffc331ebcba54018a''':
                docPath,
            '''hello_world_cfb7bfe4be052f5e635f9291624c97e8c45ac933c18d1b8ee0e6a80fb81d491a''':
                helloWorldPath,
            '''hooks_a765dcb6544a44c14697c793e67ab2885f2efd292b8d619739aeef699c07af5b''':
                hooksPath,
            '''greeting_7271b59f2b3d670acfa5ed607915573ed3e66bf38b4bb2cd8a7972bb3e17b239''':
                greetingPath,
            '''plugin_40192192887515a0911c28a4738bb32229909ac5d7161c00b3d9bd41accf3485''':
                pluginPath,
            '''simple_6c33a2482d658c2355275550eb6960356ef483e03badf54b9e4f7daae613acd6''':
                simplePath,
            '''todos_c8800221272babb429e8e7e5cbfce6912dcb605ea323643c52b1a9ea71f4f244''':
                todosPath,
            '''widget_3e9a45e03a5fe88eed08372ea15dce0ce1b9e2685a75e62ebd4deac7563c8704''':
                widgetPath,
          }),
        );
      printLogs = [];
      pubUpdater = MockPubUpdater();
      logger = MockLogger();

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);
      when(
        () => pubUpdater.update(packageName: packageName),
      ).thenAnswer((_) => Future.value(FakeProcessResult()));

      when(() => logger.progress(any())).thenReturn(([String? _]) {});
      commandRunner = MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test(
      '--help shows correct help information',
      overridePrint(() async {
        const expectedPrintLogs = <String>[
          'Generate code using an existing brick template.\n'
              '\n'
              'Usage: mason make <subcommand> [arguments]\n'
              '-h, --help                      Print this usage information.\n'
              '    --no-hooks                  skips running hooks\n'
              '''-c, --config-path               Path to config json file containing variables.\n'''
              '''-o, --output-dir                Directory where to output the generated code.\n'''
              '                                (defaults to ".")\n'
              '''    --on-conflict               File conflict resolution strategy.\n'''
              '\n'
              '''          [append]              Always append conflicting files.\n'''
              '''          [overwrite]           Always overwrite conflicting files.\n'''
              '''          [prompt] (default)    Always prompt the user for each file conflict.\n'''
              '          [skip]                Always skip conflicting files.\n'
              '\n'
              'Available subcommands:\n'
              '  app_icon        Create an app_icon file from a URL\n'
              '  documentation   Create Documentation Markdown Files\n'
              '  greeting        A Simple Greeting Template\n'
              '  hello_world     A Simple Hello World Template\n'
              '  hooks           A Hooks Example Template\n'
              '  plugin          An example plugin template\n'
              '  simple          A Simple Static Template\n'
              '  todos           A Todos Template\n'
              '  widget          Create a Simple Flutter Widget\n'
              '\n'
              'Run "mason help" to see global options.'
        ];
        final result = await commandRunner.run(['make', '-h']);
        expect(result, equals(ExitCode.success.code));
        expect(printLogs, equals(expectedPrintLogs));
      }),
    );

    test(
      '<subcommand> --help shows correct help information',
      overridePrint(() async {
        const expectedPrintLogs = <String>[
          'A Simple Greeting Template\n'
              '\n'
              'Usage: mason make greeting [arguments]\n'
              '-h, --help                      Print this usage information.\n'
              '    --no-hooks                  skips running hooks\n'
              '''-c, --config-path               Path to config json file containing variables.\n'''
              '''-o, --output-dir                Directory where to output the generated code.\n'''
              '                                (defaults to ".")\n'
              '''    --on-conflict               File conflict resolution strategy.\n'''
              '\n'
              '''          [append]              Always append conflicting files.\n'''
              '''          [overwrite]           Always overwrite conflicting files.\n'''
              '''          [prompt] (default)    Always prompt the user for each file conflict.\n'''
              '          [skip]                Always skip conflicting files.\n'
              '\n'
              '    --name                      \n'
              '\n'
              'Run "mason help" to see global options.'
        ];
        final testDir = Directory(
          path.join(Directory.current.path, 'greeting'),
        )..createSync(recursive: true);
        Directory.current = testDir.path;
        final result = await commandRunner.run(['make', 'greeting', '--help']);
        expect(result, equals(ExitCode.success.code));
        expect(printLogs, equals(expectedPrintLogs));
      }),
    );

    test('exits with code 64 when brick does not exist', () async {
      final result = await commandRunner.run(['make', 'garbage']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err(
          'Could not find a subcommand named "garbage" for "mason make".',
        ),
      ).called(1);
    });

    test('exits with code 64 when missing subcommand', () async {
      final result = await commandRunner.run(['make']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err('Missing subcommand for "mason make".'),
      ).called(1);
    });

    test('exits with code 64 when local mason.yaml does not exist', () async {
      try {
        File(path.join(Directory.current.path, 'mason.yaml'))
            .deleteSync(recursive: true);
      } catch (_) {}
      commandRunner = MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
      final result = await commandRunner.run(['make', 'garbage']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err(
          'Could not find a subcommand named "garbage" for "mason make".',
        ),
      ).called(1);
    });

    test('exits with code 64 when json decode fails', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'todos'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      File(path.join(testDir.path, 'todos.json'))
          .writeAsStringSync('''{"todos": [}''');
      final result = await commandRunner.run([
        'make',
        'todos',
        '--config-path',
        'todos.json',
      ]);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err(
          '''
FormatException: Unexpected character (at character 12)
{"todos": [}
           ^
in todos.json''',
        ),
      ).called(1);
    });

    test('exits with code 64 when config does not exist', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'todos'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run([
        'make',
        'todos',
        '--config-path',
        'todos.json',
      ]);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err(
          '''
FileSystemException: Cannot open file, path = 'todos.json' (OS Error: No such file or directory, errno = 2)''',
        ),
      ).called(1);
    });

    test('exits with code 64 when mason.yaml contains mismatch', () async {
      File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  app_icon1:
    path: ../../../../../bricks/app_icon
''',
      );
      commandRunner = MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
      final getResult = await commandRunner.run(['get']);
      expect(getResult, equals(ExitCode.success.code));
      final makeResult = await commandRunner.run(['make', 'app_icon1']);
      expect(makeResult, equals(ExitCode.usage.code));
      final expectedErrorMessage = MasonYamlNameMismatch(
        '''brick name "app_icon" doesn't match provided name "app_icon1" in mason.yaml.''',
      ).message;
      verify(() => logger.err(expectedErrorMessage)).called(1);
    });

    test(
        'exits with code 73 when exception occurs '
        'decoding prompt response', () async {
      final result = await commandRunner.run(['make', 'app_icon']);
      expect(result, equals(ExitCode.cantCreate.code));
      verify(
        () => logger.err("type 'Null' is not a subtype of type 'String'"),
      ).called(1);
    });

    test('exits with code 73 when exception occurs while generating', () async {
      const url =
          'https://cdn.dribbble.com/users/163325/screenshots/6214023/app_icon.jpg';
      when(() => logger.prompt('url: ')).thenReturn(url);
      final testDir = Directory(
        path.join(Directory.current.path, 'app_icon_conflict'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      File(path.join(testDir.path, 'app_icon.jpg')).writeAsStringSync('');
      final result = await commandRunner.run(['make', 'app_icon']);
      expect(result, equals(ExitCode.cantCreate.code));
      verify(
        () => logger.err("type 'Null' is not a subtype of type 'String'"),
      ).called(1);
    });

    test('generates app_icon (from args)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'app_icon'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run([
        'make',
        'app_icon',
        '--url',
        'https://cdn.dribbble.com/users/163325/screenshots/6214023/app_icon.jpg'
      ]);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'app_icon'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'app_icon'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates app_icon (from prompt)', () async {
      const url =
          'https://cdn.dribbble.com/users/163325/screenshots/6214023/app_icon.jpg';
      when(() => logger.prompt(any())).thenReturn(url);
      final testDir = Directory(
        path.join(Directory.current.path, 'app_icon'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run(['make', 'app_icon']);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'app_icon'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'app_icon'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates documentation', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'documentation'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run([
        'make',
        'documentation',
        '--name',
        'test-name',
        '--description',
        'test-description',
        '--author',
        'test-author'
      ]);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'documentation'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'documentation'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates greeting', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'greeting'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run([
        'make',
        'greeting',
        '--name',
        'test-name',
      ]);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'greeting'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'greeting'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates hello_world', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'hello_world'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run([
        'make',
        'hello_world',
        '--name',
        'dash',
      ]);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'hello_world'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'hello_world'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates hooks', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'hooks', 'basic'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run([
        'make',
        'hooks',
        '--name',
        'dash',
      ]);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'hooks', 'basic'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'hooks', 'basic'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates hooks (--no-hooks)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'hooks', 'no_hooks'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run([
        'make',
        'hooks',
        '--name',
        'dash',
        '--no-hooks',
      ]);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'hooks', 'no_hooks'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'hooks', 'no_hooks'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates plugin (empty)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'plugin', 'empty'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run(
        ['make', 'plugin', '--ios', 'false', '--android', 'false'],
      );
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'plugin', 'empty'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'plugin', 'empty'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates plugin (android)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'plugin', 'android'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run(
        ['make', 'plugin', '--ios', 'false', '--android', 'true'],
      );
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'plugin', 'android'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'plugin', 'android'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates plugin (ios)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'plugin', 'ios'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run(
        ['make', 'plugin', '--ios', 'true', '--android', 'false'],
      );
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'plugin', 'ios'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'plugin', 'ios'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates plugin (android + ios)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'plugin', 'android_ios'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run(
        ['make', 'plugin', '--ios', 'true', '--android', 'true'],
      );
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(
          testFixturesPath(cwd, suffix: '.make'),
          'plugin',
          'android_ios',
        ),
      );
      final expected = Directory(
        path.join(
          testFixturesPath(cwd, suffix: 'make'),
          'plugin',
          'android_ios',
        ),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates simple', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'simple'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run(['make', 'simple']);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'simple'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'simple'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates todos', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'todos'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      File(path.join(testDir.path, 'todos.json')).writeAsStringSync(
        '''
{
  "todos": [
    { "todo": "Eat", "done": true },
    { "todo": "Code", "done": true },
    { "todo": "Sleep", "done": false }
  ],
  "developers": [{ "name": "Alex" }, { "name": "Sam" }, { "name": "Jen" }]
}
''',
      );
      final result = await commandRunner.run([
        'make',
        'todos',
        '-c',
        'todos.json',
      ]);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'todos'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'todos'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates widget', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'widget'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run([
        'make',
        'widget',
        '--name',
        'my_widget',
      ]);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'widget'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'widget'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates greeting with custom output directory', () async {
      final result = await commandRunner.run(
        [
          'make',
          'greeting',
          '--name',
          'test-name',
          '-o',
          path.join('output_dir', 'dir')
        ],
      );
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'output_dir', 'dir'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'output_dir', 'dir'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates greeting and skips conflicts', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'greeting-skip'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      var result = await commandRunner.run([
        'make',
        'greeting',
        '--name',
        'test-name',
      ]);
      expect(result, equals(ExitCode.success.code));

      final fileA = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileA.readAsStringSync(), contains('Hi test-name!'));
      verify(
        () => logger.delayed(any(that: contains('(new)'))),
      ).called(1);

      result = await commandRunner.run([
        'make',
        'greeting',
        '--name',
        'test-name2',
        '--on-conflict',
        'skip',
      ]);

      expect(result, equals(ExitCode.success.code));
      final fileB = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileB.readAsStringSync(), contains('Hi test-name!'));
      verify(
        () => logger.delayed(any(that: contains('(skip)'))),
      ).called(1);
    });

    test('generates greeting and overwrites conflicts', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'greeting-overwrite'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      var result = await commandRunner.run([
        'make',
        'greeting',
        '--name',
        'test-name',
      ]);
      expect(result, equals(ExitCode.success.code));

      final fileA = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileA.readAsStringSync(), contains('Hi test-name!'));
      verify(
        () => logger.delayed(any(that: contains('(new)'))),
      ).called(1);

      result = await commandRunner.run([
        'make',
        'greeting',
        '--name',
        'test-name2',
        '--on-conflict',
        'overwrite',
      ]);

      expect(result, equals(ExitCode.success.code));
      final fileB = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileB.readAsStringSync(), contains('Hi test-name2!'));
      verify(
        () => logger.delayed(any(that: contains('(new)'))),
      ).called(1);
    });

    test('generates greeting and appends to existing file', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'greeting-append'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      var result = await commandRunner.run([
        'make',
        'greeting',
        '--name',
        'test-name',
      ]);
      expect(result, equals(ExitCode.success.code));

      final fileA = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileA.readAsStringSync(), contains('Hi test-name!'));
      verify(
        () => logger.delayed(any(that: contains('(new)'))),
      ).called(1);

      result = await commandRunner.run([
        'make',
        'greeting',
        '--name',
        'test-name2',
        '--on-conflict',
        'append',
      ]);

      expect(result, equals(ExitCode.success.code));
      final fileB = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileB.readAsStringSync(), contains('Hi test-name!Hi test-name2!'));
      verify(
        () => logger.delayed(any(that: contains('(modified)'))),
      ).called(1);
    });
  });
}
