import 'package:mason/mason.dart';
import 'package:mason/src/command_runner.dart';
import 'package:mason/src/io.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  final cwd = Directory.current;

  group('mason bundle', () {
    late Logger logger;
    late MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      commandRunner = MasonCommandRunner(logger: logger);
      when(() => logger.progress(any())).thenReturn(([String? _]) {});
      setUpTestingEnvironment(cwd, suffix: '.bundle');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('creates a new universal bundle (no hooks)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'universal'),
      )..createSync(recursive: true);
      final brickPath = path.join('..', '..', '..', '..', 'bricks', 'greeting');
      Directory.current = testDir.path;
      final result = await commandRunner.run(['bundle', brickPath]);
      expect(result, equals(ExitCode.success.code));
      final actual = File(
        path.join(
          testFixturesPath(cwd, suffix: '.bundle'),
          'universal',
          'greeting.bundle',
        ),
      ).readAsStringSync();
      final expected =
          '''{"files":[{"path":"GREETINGS.md","data":"SGkge3tuYW1lfX0h","type":"text"}],"hooks":[],"name":"greeting","description":"A Simple Greeting Template","vars":["name"]}''';
      expect(actual, equals(expected));
    });

    test('creates a new universal bundle (with hooks)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'universal'),
      )..createSync(recursive: true);
      final brickPath = path.join('..', '..', '..', '..', 'bricks', 'hooks');
      Directory.current = testDir.path;
      final result = await commandRunner.run(['bundle', brickPath]);
      expect(result, equals(ExitCode.success.code));
      final actual = File(
        path.join(
          testFixturesPath(cwd, suffix: '.bundle'),
          'universal',
          'hooks.bundle',
        ),
      ).readAsStringSync();
      final expected =
          '''{"files":[{"path":"hooks.md","data":"SGkge3tuYW1lfX0h","type":"text"}],"hooks":[{"path":"post_gen.dart","data":"aW1wb3J0ICdkYXJ0OmlvJzsKCnZvaWQgbWFpbigpIHsKICBmaW5hbCBmaWxlID0gRmlsZSgnLnBvc3RfZ2VuLnR4dCcpOwogIGZpbGUud3JpdGVBc1N0cmluZ1N5bmMoJ3Bvc3RfZ2VuOiB7e25hbWV9fScpOwp9","type":"text"},{"path":"pre_gen.dart","data":"aW1wb3J0ICdkYXJ0OmlvJzsKCnZvaWQgbWFpbigpIHsKICBmaW5hbCBmaWxlID0gRmlsZSgnLnByZV9nZW4udHh0Jyk7CiAgZmlsZS53cml0ZUFzU3RyaW5nU3luYygncHJlX2dlbjoge3tuYW1lfX0nKTsKfQ==","type":"text"}],"name":"hooks","description":"A Hooks Example Template","vars":["name"]}''';
      expect(actual, equals(expected));
    });

    test('creates a new dart bundle (no hooks)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'dart'),
      )..createSync(recursive: true);
      final brickPath = path.join('..', '..', '..', '..', 'bricks', 'greeting');
      Directory.current = testDir.path;
      final result = await commandRunner.run(
        ['bundle', brickPath, '-t', 'dart'],
      );
      expect(result, equals(ExitCode.success.code));
      final actual = File(
        path.join(
          testFixturesPath(cwd, suffix: '.bundle'),
          'dart',
          'greeting_bundle.dart',
        ),
      ).readAsStringSync();
      expect(
        actual,
        contains(
          '// ignore_for_file: prefer_single_quotes, public_member_api_docs, lines_longer_than_80_chars, implicit_dynamic_list_literal',
        ),
      );
      expect(actual, contains("import 'package:mason/mason.dart'"));
      expect(
        actual,
        contains(
          '''final greetingBundle = MasonBundle.fromJson(<String, dynamic>{"files":[{"path":"GREETINGS.md","data":"SGkge3tuYW1lfX0h","type":"text"}],"hooks":[],"name":"greeting","description":"A Simple Greeting Template","vars":["name"]});''',
        ),
      );
    });

    test('creates a new dart bundle (with hooks)', () async {
      final testDir = Directory(
        path.join(Directory.current.path, 'dart'),
      )..createSync(recursive: true);
      final brickPath = path.join('..', '..', '..', '..', 'bricks', 'hooks');
      Directory.current = testDir.path;
      final result = await commandRunner.run(
        ['bundle', brickPath, '-t', 'dart'],
      );
      expect(result, equals(ExitCode.success.code));
      final actual = File(
        path.join(
          testFixturesPath(cwd, suffix: '.bundle'),
          'dart',
          'hooks_bundle.dart',
        ),
      ).readAsStringSync();
      expect(
        actual,
        contains(
          '// ignore_for_file: prefer_single_quotes, public_member_api_docs, lines_longer_than_80_chars, implicit_dynamic_list_literal',
        ),
      );
      expect(actual, contains("import 'package:mason/mason.dart'"));
      expect(
        actual,
        contains(
          '''final hooksBundle = MasonBundle.fromJson(<String, dynamic>{"files":[{"path":"hooks.md","data":"SGkge3tuYW1lfX0h","type":"text"}],"hooks":[{"path":"post_gen.dart","data":"aW1wb3J0ICdkYXJ0OmlvJzsKCnZvaWQgbWFpbigpIHsKICBmaW5hbCBmaWxlID0gRmlsZSgnLnBvc3RfZ2VuLnR4dCcpOwogIGZpbGUud3JpdGVBc1N0cmluZ1N5bmMoJ3Bvc3RfZ2VuOiB7e25hbWV9fScpOwp9","type":"text"},{"path":"pre_gen.dart","data":"aW1wb3J0ICdkYXJ0OmlvJzsKCnZvaWQgbWFpbigpIHsKICBmaW5hbCBmaWxlID0gRmlsZSgnLnByZV9nZW4udHh0Jyk7CiAgZmlsZS53cml0ZUFzU3RyaW5nU3luYygncHJlX2dlbjoge3tuYW1lfX0nKTsKfQ==","type":"text"}],"name":"hooks","description":"A Hooks Example Template","vars":["name"]});''',
        ),
      );
    });

    test('exits with code 64 when no brick path is provided', () async {
      final result = await commandRunner.run(['bundle']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err('path to the brick template must be provided'),
      ).called(1);
    });

    test('exits with code 64 when no brick exists at path', () async {
      final brickPath = path.join('path', 'to', 'brick');
      final result = await commandRunner.run(['bundle', brickPath]);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err('could not find brick at $brickPath'),
      ).called(1);
    });
  });
}
