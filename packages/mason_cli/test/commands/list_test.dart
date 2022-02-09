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

void main() {
  final cwd = Directory.current;

  group('mason list', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late MasonCommandRunner commandRunner;

    setUp(() async {
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
      setUpTestingEnvironment(cwd, suffix: '.list');
      await commandRunner.run(['cache', 'clear']);
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('exits successfully when no bricks are available', () async {
      final result = await commandRunner.run(['list']);
      expect(result, equals(ExitCode.success.code));
      verify(() => logger.info('└── (empty)')).called(1);
    });

    test('ls is available as an alias', () async {
      final result = await commandRunner.run(['ls']);
      expect(result, equals(ExitCode.success.code));
      verify(() => logger.info('└── (empty)')).called(1);
    });

    test(
        'exits successfully and lists local bricks '
        'when local and global bricks are available', () async {
      final greetingPath =
          p.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
      File(p.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  documentation:
    path: ../../../../../bricks/documentation
  todos:
    path: ../../../../../bricks/todos
  widget:
    git:
      url: https://github.com/felangel/mason
      path: bricks/widget
''',
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(['get']),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(
          ['add', '-g', '--source', 'path', greetingPath],
        ),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(
          ['list'],
        ),
        completion(ExitCode.success.code),
      );

      verifyInOrder([
        () => logger.info(
              '''├── ${styleBold.wrap('documentation')} - Create Documentation Markdown Files''',
            ),
        () => logger.info('├── ${styleBold.wrap('todos')} - A Todos Template'),
        () => logger.info(
              '''└── ${styleBold.wrap('widget')} - Create a Simple Flutter Widget''',
            ),
      ]);
    });

    test(
        'exits successfully and lists local bricks '
        'sorted alphabetically', () async {
      final greetingPath =
          p.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
      File(p.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  todos:
    path: ../../../../../bricks/todos
  documentation:
    path: ../../../../../bricks/documentation
  widget:
    git:
      url: https://github.com/felangel/mason
      path: bricks/widget
''',
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(['get']),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(
          ['add', '-g', '--source', 'path', greetingPath],
        ),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(
          ['list'],
        ),
        completion(ExitCode.success.code),
      );

      verifyInOrder([
        () => logger.info(
              '''├── ${styleBold.wrap('documentation')} - Create Documentation Markdown Files''',
            ),
        () => logger.info('├── ${styleBold.wrap('todos')} - A Todos Template'),
        () => logger.info(
              '''└── ${styleBold.wrap('widget')} - Create a Simple Flutter Widget''',
            ),
      ]);
    });

    test(
        'exits successfully and lists global bricks '
        'when local and global bricks are available', () async {
      final greetingPath =
          p.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
      File(p.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  documentation:
    path: ../../../../../bricks/documentation
  todos:
    path: ../../../../../bricks/todos
  widget:
    git:
      url: https://github.com/felangel/mason
      path: bricks/widget
''',
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(['get']),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(
          ['add', '-g', '--source', 'path', greetingPath],
        ),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(
          ['list', '-g'],
        ),
        completion(ExitCode.success.code),
      );

      verify(
        () => logger.info(
          '└── ${styleBold.wrap('greeting')} - A Simple Greeting Template',
        ),
      ).called(1);
    });
  });
}
