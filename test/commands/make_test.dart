// ignore_for_file: no_adjacent_strings_in_list
import 'dart:convert';

import 'package:mason/mason.dart';
import 'package:mason/src/command_runner.dart';
import 'package:mason/src/io.dart';
import 'package:mason/src/version.dart';
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
      File(path.join(Directory.current.path, 'mason.yaml'))
        ..writeAsStringSync('''bricks:
  app_icon:
    path: ../../../bricks/app_icon
  documentation:
    path: ../../../bricks/documentation
  greeting:
    path: ../../../bricks/greeting
  hello_world:
    path: ../../../bricks/hello_world
  plugin:
    path: ../../../bricks/plugin
  simple:
    path: ../../../bricks/simple
  todos:
    path: ../../../bricks/todos
  widget:
    path: ../../../bricks/widget
''');
      final bricksPath = path.join('..', '..', '..', 'bricks');
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
        ..writeAsStringSync(json.encode({
          '''app_icon_cfe75d2168207dcf5ee22960c0260e93ee4168306dbeb09348c262bd7c73906e''':
              appIconPath,
          '''documentation_a4bd9a921f7902c67a8ae5918498ce13c8136233c3d11d835207447386ddd650''':
              docPath,
          '''greeting_81a4ec348561cdd721c3bb79b3d6dc14738bf17f02e18810dad2a6d88732e298''':
              greetingPath,
          '''hello_world_fd66b903d5885651238b50e1205b0cf05f30573cc3b4a7a4f2d1f495edd33630''':
              helloWorldPath,
          '''plugin_de4be97b1f4014112763f13689b00186175e5116db6bec26ee494b46f3ad8756''':
              pluginPath,
          '''simple_3bbc2ade88745ef690063c8f652631a4870ee6af619a327e297084251aebe232''':
              simplePath,
          '''todos_6d110323da1d9f3a3ae2ecc6feae02edef8af68ca329601f33ee29e725f1f740''':
              todosPath,
          '''widget_02426be7ece33230d574cb7a76eb7a9a595a79cbf53a1b1c8f2f1de78dfbe23f''':
              widgetPath,
        }));
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

    test('--help shows correct help information', overridePrint(() async {
      const expectedPrintLogs = <String>[
        'Generate code using an existing brick template.\n'
            '\n'
            'Usage: mason make <subcommand> [arguments]\n'
            '-h, --help                      Print this usage information.\n'
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
    }));

    test('<subcommand> --help shows correct help information',
        overridePrint(() async {
      const expectedPrintLogs = <String>[
        'A Simple Greeting Template\n'
            '\n'
            'Usage: mason make greeting [arguments]\n'
            '-h, --help                      Print this usage information.\n'
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
    }));

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
          '''FormatException: Unexpected character (at character 12)
{"todos": [}
           ^
in todos.json''',
        ),
      ).called(1);
    });

    test('generates app_icon', () async {
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
      File(path.join(testDir.path, 'todos.json')).writeAsStringSync('''{
  "todos": [
    { "todo": "Eat", "done": true },
    { "todo": "Code", "done": true },
    { "todo": "Sleep", "done": false }
  ],
  "developers": [{ "name": "Alex" }, { "name": "Sam" }, { "name": "Jen" }]
}
''');
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
