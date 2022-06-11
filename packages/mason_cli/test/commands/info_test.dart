import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_cli/src/command_runner.dart';
import 'package:mason_cli/src/version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

class MockProgress extends Mock implements Progress {}

void main() {
  final cwd = Directory.current;

  group('mason info', () {
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
      setUpTestingEnvironment(cwd, suffix: '.info');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('exits with code 64 when brick is not provided', () async {
      final result = await commandRunner.run(['info']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err('brick name is required.')).called(1);
    });

    test('exits with code 65 when brick is not found', () async {
      final result = await commandRunner.run(['info', 'unknown']);
      expect(result, equals(ExitCode.data.code));
      verify(() => logger.err('unknown brick not found.')).called(1);
    });

    test(
        'exits successfully and display brick info '
        'in console format', () async {
      File(p.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  todos:
    path: ../../../../../bricks/todos
''',
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(['get']),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(
          ['info', 'todos'],
        ),
        completion(ExitCode.success.code),
      );
      verifyInOrder([
        () => logger.info('''Name: todos'''),
        () => logger.info('''Description: A Todos Template'''),
        () => logger.info('''Version: 0.1.0+1'''),
      ]);
    });

    test(
        'exits successfully and display brick info '
        'in json format', () async {
      final todosBrickPath = p.join(
        Directory.current.path,
        '..',
        '..',
        '..',
        '..',
        '..',
        'bricks',
        'todos',
      );
      final todosBrickYaml = p.normalize(
        p.join(
          todosBrickPath,
          'brick.yaml',
        ),
      );

      File(p.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  todos:
    path: ../../../../../bricks/todos
''',
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(['get']),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(
          ['info', 'todos', '--format', 'json'],
        ),
        completion(ExitCode.success.code),
      );
      verify(
        () => logger.info(
          '''{"name":"todos","description":"A Todos Template","version":"0.1.0+1","environment":{"mason":"any"},"vars":{"todos":{"type":"string","description":"JSON Array of todos ([{\\"todo\\":\\"Walk Dog\\",\\"done\\":false}])","default":"[{\\"todo\\":\\"Walk Dog\\",\\"done\\":false}]","prompt":"What is the list of todos?"},"developers":{"type":"string","description":"JSON Array of developers ([{'name': 'Dash'}])","default":"[{\\"name\\": \\"Dash\\"}]","prompt":"What is the list of developers?"}},"path":"$todosBrickYaml"}''',
        ),
      ).called(1);
    });
  });
}
