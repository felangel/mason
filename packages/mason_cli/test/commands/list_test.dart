import 'dart:io';

import 'package:mason/mason.dart' hide packageVersion;
import 'package:mason_cli/src/command_runner.dart';
import 'package:mason_cli/src/version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

class MockProgress extends Mock implements Progress {}

void main() {
  final cwd = Directory.current;

  group('mason list', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late MasonCommandRunner commandRunner;

    setUp(() async {
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
      final greetingPath = canonicalize(
        p.join('..', '..', '..', '..', '..', 'bricks', 'greeting'),
      );
      final documentationPath = canonicalize(
        p.join('..', '..', '..', '..', '..', 'bricks', 'documentation'),
      );
      final todosPath = canonicalize(
        p.join('..', '..', '..', '..', '..', 'bricks', 'todos'),
      );
      File(p.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  documentation:
    path: ../../../../../bricks/documentation
  greeting: ^0.1.0
  todos:
    path: ../../../../../bricks/todos
  widget:
    git:
      url: https://github.com/felangel/mason
      path: bricks/widget
      ref: 997bc878c93534fad17d965be7cafe948a1dbb53
''',
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(['get']),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(
          ['add', '-g', 'greeting', '--path', greetingPath],
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
              '''├── ${styleBold.wrap('documentation')} 0.1.0+1 -> $documentationPath''',
            ),
        () => logger.info(
              '''├── ${styleBold.wrap('greeting')} 0.1.0+2 -> registry.brickhub.dev''',
            ),
        () => logger.info(
              '├── ${styleBold.wrap('todos')} 0.1.0+1 -> $todosPath',
            ),
        () => logger.info(
              '''└── ${styleBold.wrap('widget')} 0.1.0+1 -> https://github.com/felangel/mason#997bc878c93534fad17d965be7cafe948a1dbb53''',
            ),
      ]);
    });

    test(
        'exits successfully and lists local bricks '
        'sorted alphabetically', () async {
      final greetingPath =
          p.join('..', '..', '..', '..', '..', 'bricks', 'greeting');
      final documentationPath = canonicalize(
        p.join('..', '..', '..', '..', '..', 'bricks', 'documentation'),
      );
      final todosPath = canonicalize(
        p.join('..', '..', '..', '..', '..', 'bricks', 'todos'),
      );
      File(p.join(Directory.current.path, 'mason.yaml')).writeAsStringSync(
        '''
bricks:
  todos:
    path: ../../../../../bricks/todos
  documentation:
    path: ../../../../../bricks/documentation
  hello_world:
    git:
      url: https://github.com/felangel/mason
      path: bricks/hello_world
      ref: 997bc878c93534fad17d965be7cafe948a1dbb53
''',
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(['get']),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner(logger: logger, pubUpdater: pubUpdater).run(
          ['add', '-g', 'greeting', '--path', greetingPath],
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
              '''├── ${styleBold.wrap('documentation')} 0.1.0+1 -> $documentationPath''',
            ),
        () => logger.info(
              '''├── ${styleBold.wrap('hello_world')} 0.1.0+1 -> https://github.com/felangel/mason#997bc878c93534fad17d965be7cafe948a1dbb53''',
            ),
        () => logger.info(
              '└── ${styleBold.wrap('todos')} 0.1.0+1 -> $todosPath',
            ),
      ]);
    });

    test(
        'exits successfully and lists global bricks '
        'when local and global bricks are available', () async {
      final greetingPath = canonicalize(
        p.join('..', '..', '..', '..', '..', 'bricks', 'greeting'),
      );
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
          ['add', '-g', 'greeting', '--path', greetingPath],
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
          '└── ${styleBold.wrap('greeting')} 0.1.0+1 -> $greetingPath',
        ),
      ).called(1);
    });
  });
}
