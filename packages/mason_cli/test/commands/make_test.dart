// ignore_for_file: no_adjacent_strings_in_list, lines_longer_than_80_chars
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason/mason.dart' as mason show packageVersion;
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/command_runner.dart';
import 'package:mason_cli/src/commands/commands.dart';
import 'package:mason_cli/src/version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class _MockArgResults extends Mock implements ArgResults {}

class _MockLogger extends Mock implements Logger {}

class _MockPubUpdater extends Mock implements PubUpdater {}

class _MockProgress extends Mock implements Progress {}

class _MockProcessSignal extends Mock implements ProcessSignal {}

void main() {
  final cwd = Directory.current;

  group('mason make', () {
    late Logger logger;
    late Progress progress;
    late PubUpdater pubUpdater;
    late MasonCommandRunner commandRunner;
    late ProcessSignal sigint;

    setUpAll(() async {
      registerFallbackValue(Object());
      logger = _MockLogger();
      pubUpdater = _MockPubUpdater();

      when(
        () => logger.prompt(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn('');
      when(() => logger.progress(any())).thenReturn(_MockProgress());
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);
      await MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(
        ['cache', 'clear'],
      );
    });

    setUp(() {
      setUpTestingEnvironment(cwd, suffix: '.make');
      const bricks = {
        'app_icon',
        'bio',
        'documentation',
        'favorite_color',
        'favorite_languages',
        'flavors',
        'greeting',
        'legacy',
        'hello_world',
        'hooks',
        'plugin',
        'random_color',
        'simple',
        'todos',
        'widget',
      };
      final bricksPath = path.join('..', '..', '..', '..', '..', 'bricks');
      final masonYamlBuffer = StringBuffer('bricks:\n');
      for (final brick in bricks) {
        masonYamlBuffer.writeln('  $brick: ${path.join(bricksPath, brick)}');
      }
      File(
        path.join(Directory.current.path, 'mason.yaml'),
      ).writeAsStringSync('$masonYamlBuffer');
      final bricksJsonContent = json.encode({
        for (final brick in bricks)
          brick: canonicalize(
            path.join(Directory.current.path, bricksPath, brick),
          ),
      });
      final bricksJson =
          File(path.join(Directory.current.path, '.mason', 'bricks.json'))
            ..createSync(recursive: true)
            ..writeAsStringSync(bricksJsonContent);

      printLogs = [];
      logger = _MockLogger();
      progress = _MockProgress();
      pubUpdater = _MockPubUpdater();

      when(
        () => logger.prompt(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn('');
      when(() => logger.progress(any())).thenReturn(progress);
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      commandRunner = MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );

      addTearDown(() {
        if (bricksJson.existsSync()) bricksJson.deleteSync(recursive: true);
      });

      sigint = _MockProcessSignal();
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
              '-q, --quiet                     Run with reduced verbosity.\n'
              '    --no-hooks                  Skips running hooks.\n'
              '    --set-exit-if-changed       Return exit code 70 if there are files modified.\n'
              '    --watch                     Watch the __brick__ directory for changes.\n'
              '-c, --config-path               Path to config json file containing variables.\n'
              '-o, --output-dir                Directory where to output the generated code.\n'
              '                                (defaults to ".")\n'
              '    --on-conflict               File conflict resolution strategy.\n'
              '\n'
              '          [prompt] (default)    Always prompt the user for each file conflict.\n'
              '          [overwrite]           Always overwrite conflicting files.\n'
              '          [append]              Always append conflicting files.\n'
              '          [skip]                Always skip conflicting files.\n'
              '\n'
              'Available subcommands:\n'
              '  app_icon             Create an app icon file from a URL\n'
              '  bio                  A Bio Template\n'
              '  documentation        Create Documentation Markdown Files\n'
              '  favorite_color       A new brick created with the Mason CLI.\n'
              '  favorite_languages   A new brick created with the Mason CLI.\n'
              '  flavors              A new brick created with the Mason CLI.\n'
              '  greeting             A Simple Greeting Template\n'
              '  hello_world          A Simple Hello World Template\n'
              '  hooks                A Hooks Example Template\n'
              '  legacy               A Legacy Greeting Template\n'
              '  plugin               An example plugin template\n'
              '  random_color         A Random Color Generator\n'
              '  simple               A Simple Static Template\n'
              '  todos                A Todos Template\n'
              '  widget               Create a Simple Flutter Widget\n'
              '\n'
              'Run "mason help" to see global options.'
        ];
        final result = await commandRunner.run(['make', '-h']);
        expect(result, equals(ExitCode.success.code));
        expect(printLogs, equals(expectedPrintLogs));
      }),
    );

    test(
      '<subcommand> --help shows correct help information (greeting)',
      overridePrint(() async {
        const expectedPrintLogs = <String>[
          'A Simple Greeting Template\n'
              '\n'
              'Usage: mason make greeting [arguments]\n'
              '-h, --help                      Print this usage information.\n'
              '-q, --quiet                     Run with reduced verbosity.\n'
              '    --no-hooks                  Skips running hooks.\n'
              '    --set-exit-if-changed       Return exit code 70 if there are files modified.\n'
              '    --watch                     Watch the __brick__ directory for changes.\n'
              '-c, --config-path               Path to config json file containing variables.\n'
              '-o, --output-dir                Directory where to output the generated code.\n'
              '                                (defaults to ".")\n'
              '    --on-conflict               File conflict resolution strategy.\n'
              '\n'
              '          [prompt] (default)    Always prompt the user for each file conflict.\n'
              '          [overwrite]           Always overwrite conflicting files.\n'
              '          [append]              Always append conflicting files.\n'
              '          [skip]                Always skip conflicting files.\n'
              '\n'
              '-------------------------------------------------------------------------------\n'
              '\n'
              '    --name                      Your name <string>\n'
              '                                (defaults to "Dash")\n'
              '\n'
              'Run "mason help" to see global options.'
        ];
        final result = await commandRunner.run(['make', 'greeting', '--help']);
        expect(result, equals(ExitCode.success.code));
        expect(printLogs, equals(expectedPrintLogs));
      }),
    );

    test(
      '<subcommand> --help shows correct help information (legacy)',
      overridePrint(() async {
        const expectedPrintLogs = <String>[
          'A Legacy Greeting Template\n'
              '\n'
              'Usage: mason make legacy [arguments]\n'
              '-h, --help                      Print this usage information.\n'
              '-q, --quiet                     Run with reduced verbosity.\n'
              '    --no-hooks                  Skips running hooks.\n'
              '    --set-exit-if-changed       Return exit code 70 if there are files modified.\n'
              '    --watch                     Watch the __brick__ directory for changes.\n'
              '-c, --config-path               Path to config json file containing variables.\n'
              '-o, --output-dir                Directory where to output the generated code.\n'
              '                                (defaults to ".")\n'
              '    --on-conflict               File conflict resolution strategy.\n'
              '\n'
              '          [prompt] (default)    Always prompt the user for each file conflict.\n'
              '          [overwrite]           Always overwrite conflicting files.\n'
              '          [append]              Always append conflicting files.\n'
              '          [skip]                Always skip conflicting files.\n'
              '\n'
              '-------------------------------------------------------------------------------\n'
              '\n'
              '    --name                      <string>\n'
              '\n'
              'Run "mason help" to see global options.'
        ];
        final result = await commandRunner.run(['make', 'legacy', '--help']);
        expect(result, equals(ExitCode.success.code));
        expect(printLogs, equals(expectedPrintLogs));
      }),
    );

    test(
      '<subcommand> --help shows correct help information (bio)',
      overridePrint(() async {
        const expectedPrintLogs = <String>[
          'A Bio Template\n'
              '\n'
              'Usage: mason make bio [arguments]\n'
              '-h, --help                      Print this usage information.\n'
              '-q, --quiet                     Run with reduced verbosity.\n'
              '    --no-hooks                  Skips running hooks.\n'
              '    --set-exit-if-changed       Return exit code 70 if there are files modified.\n'
              '    --watch                     Watch the __brick__ directory for changes.\n'
              '-c, --config-path               Path to config json file containing variables.\n'
              '-o, --output-dir                Directory where to output the generated code.\n'
              '                                (defaults to ".")\n'
              '    --on-conflict               File conflict resolution strategy.\n'
              '\n'
              '          [prompt] (default)    Always prompt the user for each file conflict.\n'
              '          [overwrite]           Always overwrite conflicting files.\n'
              '          [append]              Always append conflicting files.\n'
              '          [skip]                Always skip conflicting files.\n'
              '\n'
              '-------------------------------------------------------------------------------\n'
              '\n'
              '    --name                      Name of the current user <string>\n'
              '                                (defaults to "Dash")\n'
              '    --age                       Age of the current user <number>\n'
              '                                (defaults to 42)\n'
              '    --isDeveloper               If the current user is a developer <boolean>\n'
              '                                (defaults to false)\n'
              '\n'
              'Run "mason help" to see global options.'
        ];
        final result = await commandRunner.run(['make', 'bio', '--help']);
        expect(result, equals(ExitCode.success.code));
        expect(printLogs, equals(expectedPrintLogs));
      }),
    );

    test(
      '<subcommand> --help shows correct help information (flavors)',
      overridePrint(() async {
        const expectedPrintLogs = <String>[
          'A new brick created with the Mason CLI.\n'
              '\n'
              'Usage: mason make flavors [arguments]\n'
              '-h, --help                      Print this usage information.\n'
              '-q, --quiet                     Run with reduced verbosity.\n'
              '    --no-hooks                  Skips running hooks.\n'
              '    --set-exit-if-changed       Return exit code 70 if there are files modified.\n'
              '    --watch                     Watch the __brick__ directory for changes.\n'
              '-c, --config-path               Path to config json file containing variables.\n'
              '-o, --output-dir                Directory where to output the generated code.\n'
              '                                (defaults to ".")\n'
              '    --on-conflict               File conflict resolution strategy.\n'
              '\n'
              '          [prompt] (default)    Always prompt the user for each file conflict.\n'
              '          [overwrite]           Always overwrite conflicting files.\n'
              '          [append]              Always append conflicting files.\n'
              '          [skip]                Always skip conflicting files.\n'
              '\n'
              '-------------------------------------------------------------------------------\n'
              '\n'
              '    --flavors                   Supported flavors <array>\n'
              '                                [development, integration, staging, production]\n'
              '\n'
              'Run "mason help" to see global options.'
        ];
        final result = await commandRunner.run(['make', 'flavors', '--help']);
        expect(result, equals(ExitCode.success.code));
        expect(printLogs, equals(expectedPrintLogs));
      }),
    );

    test(
      '<subcommand> --help shows correct help information (favorite_color)',
      overridePrint(() async {
        const expectedPrintLogs = <String>[
          'A new brick created with the Mason CLI.\n'
              '\n'
              'Usage: mason make favorite_color [arguments]\n'
              '-h, --help                      Print this usage information.\n'
              '-q, --quiet                     Run with reduced verbosity.\n'
              '    --no-hooks                  Skips running hooks.\n'
              '    --set-exit-if-changed       Return exit code 70 if there are files modified.\n'
              '    --watch                     Watch the __brick__ directory for changes.\n'
              '-c, --config-path               Path to config json file containing variables.\n'
              '-o, --output-dir                Directory where to output the generated code.\n'
              '                                (defaults to ".")\n'
              '    --on-conflict               File conflict resolution strategy.\n'
              '\n'
              '          [prompt] (default)    Always prompt the user for each file conflict.\n'
              '          [overwrite]           Always overwrite conflicting files.\n'
              '          [append]              Always append conflicting files.\n'
              '          [skip]                Always skip conflicting files.\n'
              '\n'
              '-------------------------------------------------------------------------------\n'
              '\n'
              '    --color                     Your favorite color <enum>\n'
              '                                (defaults to green)\n'
              '                                [red, green, blue]\n'
              '\n'
              'Run "mason help" to see global options.'
        ];
        final result = await commandRunner.run(
          ['make', 'favorite_color', '--help'],
        );
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

    test('exits with code 70 when mason version constraint cannot be resolved',
        () async {
      await commandRunner.run(['new', 'example']);
      File(path.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
  example:
    path:  ./example
''',
        mode: FileMode.append,
      );
      await commandRunner.run(['get']);
      final brickYaml = File(path.join('example', 'brick.yaml'));
      brickYaml.writeAsStringSync(
        brickYaml.readAsStringSync().replaceFirst(
              'mason: ^${mason.packageVersion}',
              'mason: ">=99.99.99 <100.0.0"',
            ),
      );

      commandRunner = MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );

      final result = await commandRunner.run(['make', 'example']);
      expect(result, equals(ExitCode.software.code));
      verify(
        () => logger.err(
          '''The current mason version is ${mason.packageVersion}.\nBecause example requires mason version >=99.99.99 <100.0.0, version solving failed.''',
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
          any(that: contains("Cannot open file, path = 'todos.json")),
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

      File(
        path.join(Directory.current.path, '.mason', 'bricks.json'),
      ).writeAsStringSync(
        json.encode({'app_icon1': '../../../../../bricks/app_icon'}),
      );
      commandRunner = MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
      final makeResult = await commandRunner.run(['make', 'app_icon1']);
      expect(makeResult, equals(ExitCode.usage.code));
      const expectedErrorMessage =
          '''Could not find a subcommand named "app_icon1" for "mason make".''';

      verify(
        () => logger.err(any(that: contains(expectedErrorMessage))),
      ).called(1);
    });

    test('exits with code 64 when bricks.json contains bad path', () async {
      File(path.join(Directory.current.path, '.mason', 'bricks.json'))
          .writeAsStringSync('''{"greeting1":"bricks/greeting"}''');
      commandRunner = MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
      final makeResult = await commandRunner.run(['make', 'greeting']);
      expect(makeResult, equals(ExitCode.usage.code));
      const expectedErrorMessage = 'Could not find brick at bricks/greeting';
      verify(() => logger.err(expectedErrorMessage)).called(1);
    });

    test('exits with code 64 when variable input has type mismatch', () async {
      when(
        () => logger.prompt(
          any(that: contains('What is your name?')),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn('Dash');
      when(
        () => logger.prompt(
          any(that: contains('How old are you?')),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn('abc');
      final result = await commandRunner.run(['make', 'bio']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err('Invalid age.\n"abc" is not a number.'),
      ).called(1);
    });

    test('exits with code 70 when exception occurs while generating', () async {
      const url =
          'https://storage.googleapis.com/cms-storage-bucket/c823e53b3a1a7b0d36a9.png';
      when(
        () => logger.prompt(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn(url);
      final progress = _MockProgress();
      when(() => progress.complete(any())).thenAnswer((invocation) {
        final update = invocation.positionalArguments[0] as String?;
        if (update?.contains('Generated') ?? false) throw Exception('oops');
      });
      when(() => logger.progress(any())).thenReturn(progress);
      final result = await commandRunner.run(['make', 'app_icon']);
      expect(result, equals(ExitCode.software.code));
      verify(() => logger.err('Exception: oops')).called(1);
    });

    test('exits with code 70 when exception occurs post generation', () async {
      when(() => logger.flush(any())).thenThrow(Exception('oops'));
      final result = await commandRunner.run(
        ['make', 'greeting', '--name', 'test-name'],
      );
      expect(result, equals(ExitCode.software.code));
      verify(() => logger.err('Exception: oops')).called(1);
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
        'https://storage.googleapis.com/cms-storage-bucket/c823e53b3a1a7b0d36a9.png',
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
          'https://storage.googleapis.com/cms-storage-bucket/c823e53b3a1a7b0d36a9.png';
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

    test('generates bio (from prompt)', () async {
      when(
        () => logger.prompt(
          any(that: contains('What is your name?')),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn('Dash');
      when(
        () => logger.prompt(
          any(that: contains('How old are you?')),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn('42');
      when(
        () => logger.confirm(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn(false);
      final testDir = Directory(
        path.join(Directory.current.path, 'bio'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run(['make', 'bio']);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'bio'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'bio'),
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
        'test-author',
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

    test('generates favorite_color', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'favorite_color'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      when(
        () => logger.chooseOne<String>(
          any(),
          choices: any(named: 'choices'),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn('blue');
      final result = await commandRunner.run(['make', 'favorite_color']);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'favorite_color'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'favorite_color'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('generates favorite_languages', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'favorite_languages'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      when(
        () => logger.promptAny(any()),
      ).thenReturn(['dart', 'rust', 'c++']);
      final result = await commandRunner.run(['make', 'favorite_languages']);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'favorite_languages'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'favorite_languages'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('throws FormatException when enum values is empty', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'enum_no_choices'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;

      await commandRunner.run([
        'add',
        'enum_no_choices',
        '--path',
        canonicalize(
          path.join(
            Directory.current.path,
            '..',
            '..',
            '..',
            'bricks',
            'enum_no_choices',
          ),
        ),
      ]);

      final result = await MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      ).run(['make', 'enum_no_choices']);
      expect(result, equals(ExitCode.usage.code));

      verify(
        () => logger.err(
          'Invalid color.\n"Enums must have at least one value.',
        ),
      ).called(1);
    });

    test('generates flavors', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'flavors'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      when(
        () => logger.chooseAny<String>(
          any(),
          choices: any(named: 'choices'),
          defaultValues: any(named: 'defaultValues'),
        ),
      ).thenReturn(['development', 'production']);
      final result = await commandRunner.run(['make', 'flavors']);
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'flavors'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'flavors'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
    });

    test('throws FormatException when array values is empty', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'array_no_choices'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;

      await commandRunner.run([
        'add',
        'array_no_choices',
        '--path',
        canonicalize(
          path.join(
            Directory.current.path,
            '..',
            '..',
            '..',
            'bricks',
            'array_no_choices',
          ),
        ),
      ]);

      final result = await MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      ).run(['make', 'array_no_choices']);
      expect(result, equals(ExitCode.usage.code));

      verify(
        () => logger.err(
          'Invalid colors.\n"Arrays must have at least one value.',
        ),
      ).called(1);
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

    test('generates random_color', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'random_color'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run([
        'make',
        'random_color',
        '--name',
        'dash',
      ]);
      expect(result, equals(ExitCode.success.code));

      final file = File(
        path.join(
          testFixturesPath(cwd, suffix: '.make'),
          'random_color',
          'color.md',
        ),
      );
      expect(file.existsSync(), isTrue);
      final contents = file.readAsStringSync();
      expect(contents, contains('Hi dash!'));
      expect(contents, contains('Your favorite color is'));
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
          path.join('output_dir', 'dir'),
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
        () => logger.delayed(
          '''  ${green.wrap('created')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
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
        () => logger.delayed(
          '''  ${yellow.wrap('skipped')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
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
        () => logger.delayed(
          '''  ${green.wrap('created')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
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
        () => logger.delayed(
          '''  ${green.wrap('created')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
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
        () => logger.delayed(
          '''  ${green.wrap('created')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
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
        () => logger.delayed(
          '''  ${lightBlue.wrap('modified')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
      ).called(1);
    });

    test('generates greeting --set-exit-if-changed (identical)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'greeting-set-exit-if-changed'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      var result = await commandRunner.run(
        ['make', 'greeting', '--name', 'test-name', '--set-exit-if-changed'],
      );
      expect(result, equals(ExitCode.software.code));

      final fileA = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileA.readAsStringSync(), contains('Hi test-name!'));
      verify(
        () => logger.delayed(
          '''  ${green.wrap('created')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
      ).called(1);
      verify(
        () => logger.err(any(that: contains('1 file changed'))),
      ).called(1);

      result = await commandRunner.run([
        'make',
        'greeting',
        '--name',
        'test-name',
        '--on-conflict',
        'overwrite',
        '--set-exit-if-changed',
      ]);

      expect(result, equals(ExitCode.success.code));
      final fileB = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileB.readAsStringSync(), contains('Hi test-name!'));
      verify(
        () => logger.delayed(
          '''  ${cyan.wrap('identical')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
      ).called(1);
      verify(
        () => logger.info(any(that: contains('0 files changed'))),
      ).called(1);
    });

    test('generates greeting --set-exit-if-changed (overwritten)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'greeting-set-exit-if-changed'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      var result = await commandRunner.run(
        ['make', 'greeting', '--name', 'test-name', '--set-exit-if-changed'],
      );
      expect(result, equals(ExitCode.software.code));

      final fileA = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileA.readAsStringSync(), contains('Hi test-name!'));
      verify(
        () => logger.delayed(
          '''  ${green.wrap('created')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
      ).called(1);
      verify(
        () => logger.err(any(that: contains('1 file changed'))),
      ).called(1);

      result = await commandRunner.run([
        'make',
        'greeting',
        '--name',
        'test-name1',
        '--on-conflict',
        'overwrite',
        '--set-exit-if-changed',
      ]);

      expect(result, equals(ExitCode.software.code));
      final fileB = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileB.readAsStringSync(), contains('Hi test-name1!'));
      verify(
        () => logger.delayed(
          '''  ${green.wrap('created')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
      ).called(1);
      verify(
        () => logger.err(any(that: contains('1 file changed'))),
      ).called(1);
    });

    test('generates greeting --set-exit-if-changed (skipped)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'greeting-set-exit-if-changed'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      var result = await commandRunner.run(
        ['make', 'greeting', '--name', 'test-name', '--set-exit-if-changed'],
      );
      expect(result, equals(ExitCode.software.code));

      final fileA = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileA.readAsStringSync(), contains('Hi test-name!'));
      verify(
        () => logger.delayed(
          '''  ${green.wrap('created')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
      ).called(1);
      verify(
        () => logger.err(any(that: contains('1 file changed'))),
      ).called(1);

      result = await commandRunner.run([
        'make',
        'greeting',
        '--name',
        'test-name1',
        '--on-conflict',
        'skip',
        '--set-exit-if-changed',
      ]);

      expect(result, equals(ExitCode.success.code));
      final fileB = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileB.readAsStringSync(), contains('Hi test-name!'));
      verify(
        () => logger.delayed(
          '''  ${yellow.wrap('skipped')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
      ).called(1);
      verify(
        () => logger.info(any(that: contains('0 files changed'))),
      ).called(1);
    });

    test('generates greeting --set-exit-if-changed (modified)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'greeting-set-exit-if-changed'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      var result = await commandRunner.run(
        ['make', 'greeting', '--name', 'test-name', '--set-exit-if-changed'],
      );
      expect(result, equals(ExitCode.software.code));

      final fileA = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileA.readAsStringSync(), contains('Hi test-name!'));
      verify(
        () => logger.delayed(
          '''  ${green.wrap('created')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
      ).called(1);
      verify(
        () => logger.err(any(that: contains('1 file changed'))),
      ).called(1);

      result = await commandRunner.run([
        'make',
        'greeting',
        '--name',
        'test-name1',
        '--on-conflict',
        'append',
        '--set-exit-if-changed',
      ]);

      expect(result, equals(ExitCode.software.code));
      final fileB = File(
        path.join(Directory.current.path, 'GREETINGS.md'),
      );
      expect(fileB.readAsStringSync(), contains('Hi test-name!Hi test-name1!'));
      verify(
        () => logger.delayed(
          '''  ${lightBlue.wrap('modified')} ${darkGray.wrap('GREETINGS.md')}''',
        ),
      ).called(1);
      verify(
        () => logger.err(any(that: contains('1 file changed'))),
      ).called(1);
    });

    test('generates plugin --set-exit-if-changed', () async {
      final testDir = Directory(
        path.join(
          Directory.current.path,
          'plugin',
          'empty-set-exit-if-changed',
        ),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run(
        [
          'make',
          'plugin',
          '--ios',
          'false',
          '--android',
          'true',
          '--set-exit-if-changed',
        ],
      );
      expect(result, equals(ExitCode.software.code));
      verify(
        () => logger.err(any(that: contains('5 files changed'))),
      ).called(1);
    });

    test('generates hello_world (--quiet mode)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'hello_world_quiet'),
      )..createSync(recursive: true);
      Directory.current = testDir.path;
      final result = await commandRunner.run(
        ['make', 'hello_world', '--name', 'dash', '--quiet'],
      );
      expect(result, equals(ExitCode.success.code));

      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.make'), 'hello_world_quiet'),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'make'), 'hello_world'),
      );
      expect(directoriesDeepEqual(actual, expected), isTrue);
      verifyNever(() => logger.flush(any()));
    });

    test('generates brick and watches for changes (--watch)', () async {
      const watchBrick = 'watch_brick';
      final tempDirectory = Directory.systemTemp.createTempSync();

      Directory.current = tempDirectory.path;

      addTearDown(() {
        Directory.current = cwd;
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });

      final outputDirectory = Directory(
        path.join(tempDirectory.path, 'watch_output'),
      )..createSync(recursive: true);

      final watchBrickDirectory = Directory(
        path.join(tempDirectory.path, watchBrick),
      )..createSync(recursive: true);

      final localBrickTemplateDirectory = Directory(
        path.join(watchBrickDirectory.path, BrickYaml.dir),
      )..createSync(recursive: true);

      File(path.join(watchBrickDirectory.path, BrickYaml.file))
        ..createSync(recursive: true)
        ..writeAsStringSync('''
name: $watchBrick
description: A local brick that will be watched.
version: 0.1.0+1

vars:
  name:
    type: string
    description: Your name
    default: Dash
    prompt: What is your name?
''');

      final helloTemplate =
          File(path.join(localBrickTemplateDirectory.path, 'hello.md'))
            ..createSync(recursive: true)
            ..writeAsStringSync('Hello {{name}}!');

      File(path.join(tempDirectory.path, MasonYaml.file))
        ..createSync(recursive: true)
        ..writeAsStringSync('bricks:');

      await commandRunner.run(
        ['add', watchBrick, '--path', watchBrickDirectory.path],
      );

      final argResults = _MockArgResults();
      when(() => argResults.rest).thenReturn([watchBrick]);
      when(() => argResults['name']).thenReturn('Dash');
      when(() => argResults['output-dir']).thenReturn(outputDirectory.path);
      when(() => argResults['on-conflict']).thenReturn('overwrite');
      when(() => argResults['set-exit-if-changed']).thenReturn(false);
      when(() => argResults['no-hooks']).thenReturn(false);
      when(() => argResults['quiet']).thenReturn(false);
      when(() => argResults['watch']).thenReturn(true);

      final command = MakeCommand(logger: logger, sigint: sigint);
      final sigintController = StreamController<ProcessSignal>();

      addTearDown(sigintController.close);

      when(
        () => sigint.watch(),
      ).thenAnswer((_) => sigintController.stream);

      final helloOutput = File(
        path.join(outputDirectory.path, path.basename(helloTemplate.path)),
      );

      final make = command.subcommands[watchBrick]! as MasonCommand
        ..testArgResults = argResults;

      final run = make.run();

      await untilCalled(
        () => progress.complete(any(that: contains('Generated 1 file.'))),
      );

      reset(progress);

      expect(helloOutput.readAsStringSync(), equals('Hello Dash!'));

      await Future<void>.delayed(const Duration(seconds: 1));

      helloTemplate.writeAsStringSync('Hello {{name}}!!!');

      await untilCalled(
        () => progress.complete(any(that: contains('Generated 1 file.'))),
      );

      reset(progress);

      expect(helloOutput.readAsStringSync(), equals('Hello Dash!!!'));

      final byeTemplate =
          File(path.join(localBrickTemplateDirectory.path, 'bye.md'))
            ..createSync(recursive: true)
            ..writeAsStringSync('Bye {{name}}!');

      final byeOutput = File(
        path.join(outputDirectory.path, path.basename(byeTemplate.path)),
      );

      await untilCalled(
        () => progress.complete(any(that: contains('Generated 2 files.'))),
      );

      reset(progress);

      expect(byeOutput.readAsStringSync(), equals('Bye Dash!'));

      byeTemplate.deleteSync(recursive: true);

      await untilCalled(
        () => progress.complete(any(that: contains('Generated 1 file.'))),
      );

      expect(byeOutput.existsSync(), isFalse);

      sigintController.add(ProcessSignal.sigint);

      await expectLater(
        run,
        completion(equals(ProcessSignal.sigint.signalNumber)),
      );
    });
  });
}
