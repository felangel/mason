import 'dart:io';

import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/command_runner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  final cwd = Directory.current;

  group('mason list', () {
    late Logger logger;
    late MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      commandRunner = MasonCommandRunner(logger: logger);
      when(() => logger.progress(any())).thenReturn(([String? _]) {});
      setUpTestingEnvironment(cwd, suffix: '.list');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('exits successfully when no bricks are available', () async {
      final result = await commandRunner.run(['list']);
      expect(result, equals(ExitCode.success.code));
      verifyNever(() => logger.info(any()));
    });

    test('ls is available as an alis', () async {
      final result = await commandRunner.run(['ls']);
      expect(result, equals(ExitCode.success.code));
      verifyNever(() => logger.info(any()));
    });

    test(
        'exits successfully and lists all bricks '
        'when local and global bricks are available', () async {
      const url = 'https://github.com/felangel/mason';
      final greetingPath = p.join('..', '..', '..', 'bricks', 'greeting');
      final appIconPath = p.join('bricks', 'app_icon');
      File(p.join(Directory.current.path, 'mason.yaml'))
        ..writeAsStringSync('''bricks:
  documentation:
    path: ../../../bricks/documentation
  todos:
    path: ../../../bricks/todos
  widget:
    git:
      url: https://github.com/felangel/mason
      path: bricks/widget
''');
      await expectLater(
        MasonCommandRunner().run(['cache', 'clear', '--force']),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner().run(['get']),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner().run(['install', url, '--path', appIconPath]),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner().run(['install', '--source', 'path', greetingPath]),
        completion(ExitCode.success.code),
      );
      await expectLater(
        MasonCommandRunner(logger: logger).run(['list']),
        completion(ExitCode.success.code),
      );
      verify(
        () => logger.info('greeting - A Simple Greeting Template'),
      ).called(1);
      verify(
        () => logger.info('app_icon - Create an app_icon file from a URL'),
      ).called(1);
      verify(
        () => logger.info(
          'documentation - Create Documentation Markdown Files',
        ),
      ).called(1);
      verify(
        () => logger.info('todos - A Todos Template'),
      ).called(1);
      verify(
        () => logger.info('widget - Create a Simple Flutter Widget'),
      ).called(1);
    });
  });
}
