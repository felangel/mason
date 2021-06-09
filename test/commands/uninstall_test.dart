import 'dart:io';

import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/command_runner.dart';
import 'package:mason/src/bricks_json.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  final cwd = Directory.current;

  group('mason uninstall', () {
    late Logger logger;
    late MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      commandRunner = MasonCommandRunner(logger: logger);
      when(() => logger.progress(any())).thenReturn(([String? _]) {});
      setUpTestingEnvironment(cwd, suffix: '.uninstall');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('exits with code 64 when brick name is not provided', () async {
      final result = await commandRunner.run(['uninstall']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('name of the brick is required.')).called(1);
    });

    test('exits with code 64 when brick does not exist', () async {
      final result = await commandRunner.run(['uninstall', 'garbage']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('no brick named garbage was found')).called(1);
    });

    test('uninstalls successfully when brick exists', () async {
      const url = 'https://github.com/felangel/mason';
      final installResult = await commandRunner.run(
        ['install', url, '--path', 'bricks/widget'],
      );
      expect(installResult, equals(ExitCode.success.code));

      final masonYaml = File(p.join(BricksJson.globalDir.path, 'mason.yaml'));
      expect(masonYaml.readAsStringSync(), contains('widget:'));

      const key =
          '''widget_536b4405bffd371ab46f0948d0a5b9a2ac2cddb270ebc3d6f684217f7741422f''';
      final value = p.join(
        BricksJson.rootDir.path,
        'git',
        '''mason_60e936dbe81fab0463b4efd5a396c50e4fcf52484fe2aa189d46874215a10b52''',
      );
      final bricksJson = File(
        p.join(BricksJson.globalDir.path, '.mason', 'bricks.json'),
      );
      final bricksJsonContent =
          bricksJson.readAsStringSync().replaceAll(r'\\', r'\');
      expect(bricksJsonContent, contains('"$key":"$value"'));

      final uninstallResult = await commandRunner.run(['uninstall', 'widget']);
      expect(uninstallResult, equals(ExitCode.success.code));
      verify(() => logger.progress('Uninstalling widget')).called(1);

      expect(masonYaml.readAsStringSync(), isNot(contains('widget:')));
      expect(bricksJson.readAsStringSync(), isNot(contains('"$key":"$value"')));
    });
  });
}
