import 'dart:convert';
import 'dart:io';

import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_cli/src/command_runner.dart';
import 'package:mason_cli/src/version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

class MockProgress extends Mock implements Progress {}

void main() {
  final cwd = Directory.current;

  group('mason bundle', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      pubUpdater = MockPubUpdater();

      when(() => logger.progress(any())).thenReturn(MockProgress());
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      commandRunner = MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
      setUpTestingEnvironment(cwd, suffix: '.bundle');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    group('source path', () {
      test('creates a new universal bundle (no hooks)', () async {
        final testDir = Directory(
          path.join(Directory.current.path, 'universal'),
        )..createSync(recursive: true);
        final brickPath =
            path.join('..', '..', '..', '..', '..', '..', 'bricks', 'greeting');
        Directory.current = testDir.path;
        final result = await commandRunner.run(['bundle', brickPath]);
        expect(result, equals(ExitCode.success.code));
        final file = File(
          path.join(
            testFixturesPath(cwd, suffix: '.bundle'),
            'universal',
            'greeting.bundle',
          ),
        );
        final actual = json.encode(
          (await MasonBundle.fromUniversalBundle(file.readAsBytesSync()))
              .toJson(),
        );

        expect(
          actual,
          contains(
            '''{"files":[{"path":"GREETINGS.md","data":"SGkge3tuYW1lfX0h","type":"text"}],"hooks":[],"name":"greeting","description":"A Simple Greeting Template","version":"0.1.0+1","environment":{"mason":"any"},''',
          ),
        );
        expect(actual, contains('"readme":{"path":"README.md","data":"'));
        expect(actual, contains('"changelog":{"path":"CHANGELOG.md","data":"'));
        expect(actual, contains('"license":{"path":"LICENSE","data":"'));
        expect(
          actual,
          contains(
            '''"vars":{"name":{"type":"string","description":"Your name","default":"Dash","prompt":"What is your name?"}}}''',
          ),
        );
        verify(() => logger.progress('Bundling greeting')).called(1);
        verify(
          () => logger.info(
            '${lightGreen.wrap('✓')} '
            'Generated 1 file:',
          ),
        ).called(1);
        verify(
          () => logger.info(darkGray.wrap('  ${canonicalize(file.path)}')),
        ).called(1);
      });

      test('creates a new universal bundle (with hooks)', () async {
        final testDir = Directory(
          path.join(Directory.current.path, 'universal'),
        )..createSync(recursive: true);
        final brickPath =
            path.join('..', '..', '..', '..', '..', '..', 'bricks', 'hooks');
        Directory.current = testDir.path;
        final result = await commandRunner.run(['bundle', brickPath]);
        expect(result, equals(ExitCode.success.code));
        final file = File(
          path.join(
            testFixturesPath(cwd, suffix: '.bundle'),
            'universal',
            'hooks.bundle',
          ),
        );
        final actual = json.encode(
          (await MasonBundle.fromUniversalBundle(file.readAsBytesSync()))
              .toJson(),
        );
        expect(
          actual,
          contains(
            '{"path":"hooks.md","data":"SGkge3tuYW1lfX0h","type":"text"}',
          ),
        );
        expect(
          actual,
          contains(
            '''{"path":"post_gen.dart","data":"aW1wb3J0ICdkYXJ0OmlvJztpbXBvcnQgJ3BhY2thZ2U6bWFzb24vbWFzb24uZGFydCc7dm9pZCBydW4oSG9va0NvbnRleHQgY29udGV4dCl7ZmluYWwgZmlsZT1GaWxlKCcucG9zdF9nZW4udHh0Jyk7ZmlsZS53cml0ZUFzU3RyaW5nU3luYygncG9zdF9nZW46ICR7Y29udGV4dC52YXJzWyduYW1lJ119Jyk7fQ==","type":"text"}''',
          ),
        );
        expect(
          actual,
          contains(
            '''{"path":"pre_gen.dart","data":"aW1wb3J0ICdkYXJ0OmlvJztpbXBvcnQgJ3BhY2thZ2U6bWFzb24vbWFzb24uZGFydCc7dm9pZCBydW4oSG9va0NvbnRleHQgY29udGV4dCl7ZmluYWwgZmlsZT1GaWxlKCcucHJlX2dlbi50eHQnKTtmaWxlLndyaXRlQXNTdHJpbmdTeW5jKCdwcmVfZ2VuOiAke2NvbnRleHQudmFyc1snbmFtZSddfScpO30=","type":"text"}''',
          ),
        );
        expect(
          actual,
          contains(
            '''{"path":"pubspec.yaml","data":"bmFtZTogaG9va3NfaG9va3M''',
          ),
        );
        expect(
          actual,
          contains(
            '''"name":"hooks","description":"A Hooks Example Template","version":"0.1.0+1","environment":{"mason":"any"},"vars":{"name":{"type":"string","description":"Your name","default":"Dash","prompt":"What is your name?"}}''',
          ),
        );
        verify(() => logger.progress('Bundling hooks')).called(1);
        verify(
          () => logger.info(
            '${lightGreen.wrap('✓')} '
            'Generated 1 file:',
          ),
        ).called(1);
        verify(
          () => logger.info(darkGray.wrap('  ${canonicalize(file.path)}')),
        ).called(1);
      });

      test('creates a new dart bundle (no hooks)', () async {
        final testDir = Directory(
          path.join(Directory.current.path, 'dart'),
        )..createSync(recursive: true);
        final brickPath =
            path.join('..', '..', '..', '..', '..', '..', 'bricks', 'greeting');
        Directory.current = testDir.path;
        final result = await commandRunner.run(
          ['bundle', brickPath, '-t', 'dart'],
        );
        expect(result, equals(ExitCode.success.code));
        final file = File(
          path.join(
            testFixturesPath(cwd, suffix: '.bundle'),
            'dart',
            'greeting_bundle.dart',
          ),
        );
        final actual = file.readAsStringSync();
        expect(
          actual,
          contains(
            '// ignore_for_file: type=lint, implicit_dynamic_list_literal, implicit_dynamic_map_literal, inference_failure_on_collection_literal',
          ),
        );
        expect(actual, contains("import 'package:mason/mason.dart'"));
        expect(
          actual,
          contains(
            '''final greetingBundle = MasonBundle.fromJson(<String, dynamic>{"files":[{"path":"GREETINGS.md","data":"SGkge3tuYW1lfX0h","type":"text"}],"hooks":[],"name":"greeting","description":"A Simple Greeting Template","version":"0.1.0+1","environment":{"mason":"any"},''',
          ),
        );
        expect(actual, contains('"readme":{"path":"README.md","data":"'));
        expect(actual, contains('"changelog":{"path":"CHANGELOG.md","data":"'));
        expect(actual, contains('"license":{"path":"LICENSE","data":"'));
        expect(
          actual,
          contains(
            '''"vars":{"name":{"type":"string","description":"Your name","default":"Dash","prompt":"What is your name?"}}});''',
          ),
        );
        verify(() => logger.progress('Bundling greeting')).called(1);
        verify(
          () => logger.info(
            '${lightGreen.wrap('✓')} '
            'Generated 1 file:',
          ),
        ).called(1);
        verify(
          () => logger.info(darkGray.wrap('  ${canonicalize(file.path)}')),
        ).called(1);
      });

      test('creates a new dart bundle (with hooks)', () async {
        final testDir = Directory(
          path.join(Directory.current.path, 'dart'),
        )..createSync(recursive: true);
        final brickPath =
            path.join('..', '..', '..', '..', '..', '..', 'bricks', 'hooks');
        Directory.current = testDir.path;
        final result = await commandRunner.run(
          ['bundle', brickPath, '-t', 'dart'],
        );
        expect(result, equals(ExitCode.success.code));
        final file = File(
          path.join(
            testFixturesPath(cwd, suffix: '.bundle'),
            'dart',
            'hooks_bundle.dart',
          ),
        );
        final actual = file.readAsStringSync();
        expect(
          actual,
          contains(
            '// ignore_for_file: type=lint, implicit_dynamic_list_literal, implicit_dynamic_map_literal, inference_failure_on_collection_literal',
          ),
        );
        expect(actual, contains("import 'package:mason/mason.dart'"));
        expect(
          actual,
          contains(
            '''final hooksBundle = MasonBundle.fromJson(<String, dynamic>{''',
          ),
        );
        expect(
          actual,
          contains(
            '{"path":"hooks.md","data":"SGkge3tuYW1lfX0h","type":"text"}',
          ),
        );
        expect(
          actual,
          contains(
            '''{"path":"post_gen.dart","data":"aW1wb3J0ICdkYXJ0OmlvJztpbXBvcnQgJ3BhY2thZ2U6bWFzb24vbWFzb24uZGFydCc7dm9pZCBydW4oSG9va0NvbnRleHQgY29udGV4dCl7ZmluYWwgZmlsZT1GaWxlKCcucG9zdF9nZW4udHh0Jyk7ZmlsZS53cml0ZUFzU3RyaW5nU3luYygncG9zdF9nZW46ICR7Y29udGV4dC52YXJzWyduYW1lJ119Jyk7fQ==","type":"text"}''',
          ),
        );
        expect(
          actual,
          contains(
            '''{"path":"pre_gen.dart","data":"aW1wb3J0ICdkYXJ0OmlvJztpbXBvcnQgJ3BhY2thZ2U6bWFzb24vbWFzb24uZGFydCc7dm9pZCBydW4oSG9va0NvbnRleHQgY29udGV4dCl7ZmluYWwgZmlsZT1GaWxlKCcucHJlX2dlbi50eHQnKTtmaWxlLndyaXRlQXNTdHJpbmdTeW5jKCdwcmVfZ2VuOiAke2NvbnRleHQudmFyc1snbmFtZSddfScpO30=","type":"text"}''',
          ),
        );
        expect(
          actual,
          contains(
            '''{"path":"pubspec.yaml","data":"bmFtZTogaG9va3NfaG9va3M''',
          ),
        );
        expect(
          actual,
          contains(
            '''"name":"hooks","description":"A Hooks Example Template","version":"0.1.0+1","environment":{"mason":"any"},"vars":{"name":{"type":"string","description":"Your name","default":"Dash","prompt":"What is your name?"}}''',
          ),
        );
        verify(() => logger.progress('Bundling hooks')).called(1);
        verify(
          () => logger.info(
            '${lightGreen.wrap('✓')} '
            'Generated 1 file:',
          ),
        ).called(1);
        verify(
          () => logger.info(darkGray.wrap('  ${canonicalize(file.path)}')),
        ).called(1);
      });

      test('exits with code 64 when no brick path is provided', () async {
        final result = await commandRunner.run(['bundle']);
        expect(result, equals(ExitCode.usage.code));
        verify(
          () => logger.err('A path to the brick template must be provided'),
        ).called(1);
        verifyNever(() => logger.progress(any()));
      });

      test('exits with code 64 when no brick exists at path', () async {
        final brickPath = path.join('path', 'to', 'brick');
        final result = await commandRunner.run(['bundle', brickPath]);
        expect(result, equals(ExitCode.usage.code));
        verify(
          () => logger.err('Could not find brick at $brickPath'),
        ).called(1);
        verifyNever(() => logger.progress(any()));
      });

      test('exists with code 64 when exception occurs on bundling', () async {
        final progress = MockProgress();
        when(() => progress.complete(any())).thenAnswer((invocation) {
          final update = invocation.positionalArguments[0] as String?;

          if (update == 'Bundled greeting') {
            throw const MasonException('oops');
          }
        });
        when(() => logger.progress(any())).thenReturn(progress);
        final brickPath =
            path.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
        final result = await commandRunner.run(['bundle', brickPath]);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err('oops')).called(1);
      });
    });

    group('git', () {
      test('creates a new universal bundle from git', () async {
        final testDir = Directory(
          path.join(Directory.current.path, 'git'),
        )..createSync(recursive: true);
        Directory.current = testDir.path;

        const url = 'https://github.com/felangel/mason';
        final result = await commandRunner.run([
          'bundle',
          url,
          '--source',
          'git',
          '--git-path',
          'bricks/greeting',
        ]);

        expect(result, equals(ExitCode.success.code));

        final file = File(
          path.join(
            testFixturesPath(cwd, suffix: '.bundle'),
            'git',
            'greeting.bundle',
          ),
        );

        final actual = json.encode(
          (await MasonBundle.fromUniversalBundle(file.readAsBytesSync()))
              .toJson(),
        );

        expect(
          actual,
          contains(
            '''{"files":[{"path":"GREETINGS.md","data":"SGkge3tuYW1lfX0h","type":"text"}],"hooks":[],"name":"greeting","description":"A Simple Greeting Template","version":"0.1.0+1","environment":{"mason":"any"},''',
          ),
        );
        expect(actual, contains('"readme":{"path":"README.md","data":"'));
        expect(actual, contains('"changelog":{"path":"CHANGELOG.md","data":"'));
        expect(actual, contains('"license":{"path":"LICENSE","data":"'));
        expect(
          actual,
          contains(
            '''"vars":{"name":{"type":"string","description":"Your name","default":"Dash","prompt":"What is your name?"}}}''',
          ),
        );
        verify(() => logger.progress('Bundling greeting')).called(1);
        verify(
          () => logger.info(
            '${lightGreen.wrap('✓')} '
            'Generated 1 file:',
          ),
        ).called(1);
        verify(
          () => logger.info(darkGray.wrap('  ${canonicalize(file.path)}')),
        ).called(1);
      });

      test('exits with code 64 when no git url is provided', () async {
        final result = await commandRunner.run([
          'bundle',
          '--source',
          'git',
          '--git-path',
          'bricks/greeting',
        ]);
        expect(result, equals(ExitCode.usage.code));
        verify(
          () => logger.err('A repository url must be provided'),
        ).called(1);
        verifyNever(() => logger.progress(any()));
      });

      test('exits with code 64 when no brick exists at git url', () async {
        const url = 'https://github.com/felangel/mason';
        final result = await commandRunner.run([
          'bundle',
          url,
          '--source',
          'git',
        ]);

        expect(result, equals(ExitCode.usage.code));

        verify(
          () => logger.err('Could not find brick at $url'),
        ).called(1);
        verifyNever(() => logger.progress(any()));
      });
    });

    group('hosted', () {
      test('creates a new universal bundle from hosted', () async {
        final testDir = Directory(
          path.join(Directory.current.path, 'hosted'),
        )..createSync(recursive: true);
        Directory.current = testDir.path;
        final result = await commandRunner.run([
          'bundle',
          'greeting',
          '--source',
          'hosted',
        ]);

        expect(result, equals(ExitCode.success.code));

        final file = File(
          path.join(
            testFixturesPath(cwd, suffix: '.bundle'),
            'hosted',
            'greeting.bundle',
          ),
        );

        final actual = json.encode(
          (await MasonBundle.fromUniversalBundle(file.readAsBytesSync()))
              .toJson(),
        );

        expect(actual, contains('"readme":{"path":"README.md","data":"'));
        expect(actual, contains('"changelog":{"path":"CHANGELOG.md","data":"'));
        expect(actual, contains('"license":{"path":"LICENSE","data":"'));

        verify(() => logger.progress('Bundling greeting')).called(1);
        verify(
          () => logger.info(
            '${lightGreen.wrap('✓')} '
            'Generated 1 file:',
          ),
        ).called(1);
        verify(
          () => logger.info(darkGray.wrap('  ${canonicalize(file.path)}')),
        ).called(1);
      });

      test('exits with code 64 when no brick name is provided', () async {
        final result = await commandRunner.run([
          'bundle',
          '--source',
          'hosted',
        ]);

        expect(result, equals(ExitCode.usage.code));
        verify(
          () => logger.err('A brick name must be provided'),
        ).called(1);
        verifyNever(() => logger.progress(any()));
      });

      test('exits with code 64 when bundling nonexistent brick', () async {
        final result = await commandRunner.run([
          'bundle',
          'nonexistent-brick',
          '--source',
          'hosted',
        ]);

        expect(result, equals(ExitCode.usage.code));
        verify(
          () => logger.err('Brick "nonexistent-brick" does not exist.'),
        ).called(1);
        verifyNever(() => logger.progress(any()));
      });
    });
  });
}
