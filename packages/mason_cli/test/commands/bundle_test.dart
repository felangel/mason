import 'dart:convert';

import 'package:mason/mason.dart' hide packageVersion;
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

void main() {
  final cwd = Directory.current;

  group('mason bundle', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      pubUpdater = MockPubUpdater();

      when(() => logger.progress(any())).thenReturn(([String? _]) {});
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
      const expected =
          '''{"files":[{"path":"GREETINGS.md","data":"SGkge3tuYW1lfX0h","type":"text"}],"hooks":[],"name":"greeting","description":"A Simple Greeting Template","version":"0.1.0+1","environment":{"mason":"any"},"readme":{"path":"README.md","data":"IyBncmVldGluZwoKQSBuZXcgYnJpY2sgY3JlYXRlZCB3aXRoIHRoZSBNYXNvbiBDTEkuCgpfR2VuZXJhdGVkIGJ5IFttYXNvbl1bMV0g8J+nsV8KCiMjIEdldHRpbmcgU3RhcnRlZCDwn5qACgpUaGlzIGlzIGEgc3RhcnRpbmcgcG9pbnQgZm9yIGEgbmV3IGJyaWNrLgpBIGZldyByZXNvdXJjZXMgdG8gZ2V0IHlvdSBzdGFydGVkIGlmIHRoaXMgaXMgeW91ciBmaXJzdCBicmljayB0ZW1wbGF0ZToKCi0gW09mZmljaWFsIE1hc29uIERvY3VtZW50YXRpb25dWzJdCi0gW0NvZGUgZ2VuZXJhdGlvbiB3aXRoIE1hc29uIEJsb2ddWzNdCi0gW1ZlcnkgR29vZCBMaXZlc3RyZWFtOiBGZWxpeCBBbmdlbG92IERlbW9zIE1hc29uXVs0XQoKWzFdOiBodHRwczovL2dpdGh1Yi5jb20vZmVsYW5nZWwvbWFzb24KWzJdOiBodHRwczovL2dpdGh1Yi5jb20vZmVsYW5nZWwvbWFzb24vdHJlZS9tYXN0ZXIvcGFja2FnZXMvbWFzb25fY2xpI3JlYWRtZQpbM106IGh0dHBzOi8vdmVyeWdvb2QudmVudHVyZXMvYmxvZy9jb2RlLWdlbmVyYXRpb24td2l0aC1tYXNvbgpbNF06IGh0dHBzOi8veW91dHUuYmUvRzRQVGpBNnRwVFUK","type":"text"},"changelog":{"path":"CHANGELOG.md","data":"IyAwLjEuMCsxCgotIFRPRE86IERlc2NyaWJlIGluaXRpYWwgcmVsZWFzZS4K","type":"text"},"license":{"path":"LICENSE","data":"VE9ETzogQWRkIHlvdXIgbGljZW5zZSBoZXJlLgo=","type":"text"},"vars":{"name":{"type":"string","description":"Your name","default":"Dash","prompt":"What is your name?"}}}''';
      expect(actual, equals(expected));
      verify(() => logger.progress('Bundling greeting')).called(1);
      verify(
        () => logger.info(
          '${lightGreen.wrap('✓')} '
          'Generated 1 file:',
        ),
      ).called(1);
      verify(
        () => logger.detail('  ${canonicalize(file.path)}'),
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
        contains('{"path":"hooks.md","data":"SGkge3tuYW1lfX0h","type":"text"}'),
      );
      expect(
        actual,
        contains(
          '''{"path":"post_gen.dart","data":"aW1wb3J0ICdkYXJ0OmlvJztpbXBvcnQgJ3BhY2thZ2U6bWFzb24vbWFzb24uZGFydCc7dm9pZCBydW4oSG9va0NvbnRleHQgY29udGV4dCl7ZmluYWwgZmlsZT1GaWxlKCcucG9zdF9nZW4udHh0Jyk7ZmlsZS53cml0ZUFzU3RyaW5nU3luYygncG9zdF9nZW46IHt7bmFtZX19Jyk7fQ==","type":"text"}''',
        ),
      );
      expect(
        actual,
        contains(
          '''{"path":"pre_gen.dart","data":"aW1wb3J0ICdkYXJ0OmlvJztpbXBvcnQgJ3BhY2thZ2U6bWFzb24vbWFzb24uZGFydCc7dm9pZCBydW4oSG9va0NvbnRleHQgY29udGV4dCl7ZmluYWwgZmlsZT1GaWxlKCcucHJlX2dlbi50eHQnKTtmaWxlLndyaXRlQXNTdHJpbmdTeW5jKCdwcmVfZ2VuOiB7e25hbWV9fScpO30=","type":"text"}''',
        ),
      );
      expect(
        actual,
        contains('''{"path":"pubspec.yaml","data":"bmFtZTogaG9va3NfaG9va3M'''),
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
        () => logger.detail('  ${canonicalize(file.path)}'),
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
          '// ignore_for_file: prefer_single_quotes, public_member_api_docs, lines_longer_than_80_chars, implicit_dynamic_list_literal, implicit_dynamic_map_literal',
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
        () => logger.detail('  ${canonicalize(file.path)}'),
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
          '// ignore_for_file: prefer_single_quotes, public_member_api_docs, lines_longer_than_80_chars, implicit_dynamic_list_literal, implicit_dynamic_map_literal',
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
        contains('{"path":"hooks.md","data":"SGkge3tuYW1lfX0h","type":"text"}'),
      );
      expect(
        actual,
        contains(
          '''{"path":"post_gen.dart","data":"aW1wb3J0ICdkYXJ0OmlvJztpbXBvcnQgJ3BhY2thZ2U6bWFzb24vbWFzb24uZGFydCc7dm9pZCBydW4oSG9va0NvbnRleHQgY29udGV4dCl7ZmluYWwgZmlsZT1GaWxlKCcucG9zdF9nZW4udHh0Jyk7ZmlsZS53cml0ZUFzU3RyaW5nU3luYygncG9zdF9nZW46IHt7bmFtZX19Jyk7fQ==","type":"text"}''',
        ),
      );
      expect(
        actual,
        contains(
          '''{"path":"pre_gen.dart","data":"aW1wb3J0ICdkYXJ0OmlvJztpbXBvcnQgJ3BhY2thZ2U6bWFzb24vbWFzb24uZGFydCc7dm9pZCBydW4oSG9va0NvbnRleHQgY29udGV4dCl7ZmluYWwgZmlsZT1GaWxlKCcucHJlX2dlbi50eHQnKTtmaWxlLndyaXRlQXNTdHJpbmdTeW5jKCdwcmVfZ2VuOiB7e25hbWV9fScpO30=","type":"text"}''',
        ),
      );
      expect(
        actual,
        contains('''{"path":"pubspec.yaml","data":"bmFtZTogaG9va3NfaG9va3M'''),
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
        () => logger.detail('  ${canonicalize(file.path)}'),
      ).called(1);
    });

    test('exits with code 64 when no brick path is provided', () async {
      final result = await commandRunner.run(['bundle']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err('path to the brick template must be provided'),
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

    test('exists with code 64 when exception occurs during bundling', () async {
      when(() => logger.progress(any())).thenReturn(([update]) {
        if (update == 'Bundled greeting') throw const MasonException('oops');
      });
      final brickPath =
          path.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
      final result = await commandRunner.run(['bundle', brickPath]);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('oops')).called(1);
    });
  });
}
