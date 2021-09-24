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

  group('mason init', () {
    late Logger logger;
    late MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      commandRunner = MasonCommandRunner(logger: logger);
      when(() => logger.progress(any())).thenReturn(([String? _]) {});
      setUpTestingEnvironment(cwd, suffix: '.init');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('exits with code 64 when mason.yaml already exists', () async {
      final masonYaml = File(path.join(Directory.current.path, 'mason.yaml'));
      await masonYaml.create(recursive: true);
      final result = await commandRunner.run(['init']);
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err('''Existing mason.yaml at ${masonYaml.path}'''),
      ).called(1);
    });

    test('initializes mason when a mason.yaml does not exist', () async {
      final result = await commandRunner.run(['init']);
      expect(result, equals(ExitCode.success.code));
      final actual = Directory(
        path.join(testFixturesPath(cwd, suffix: '.init')),
      );
      final expected = Directory(
        path.join(testFixturesPath(cwd, suffix: 'init')),
      );
      expect(
        directoriesDeepEqual(actual, expected, ignore: ['bricks.json']),
        isTrue,
      );
      expect(
        File(path.join(actual.path, '.mason', 'bricks.json')).existsSync(),
        isTrue,
      );
      verify(() => logger.progress('Initializing')).called(1);
      verify(() => logger.progress('Getting brick')).called(1);
      verify(
        () => logger.info('Run "mason make hello" to use your first brick.'),
      ).called(1);
    });
  });
}
