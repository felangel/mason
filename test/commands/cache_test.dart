import 'dart:io';

import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/command_runner.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  final cwd = Directory.current;

  group('mason cache', () {
    Logger logger;
    MasonCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      commandRunner = MasonCommandRunner(logger: logger);
      when(logger.progress(any)).thenReturn(([String _]) {});
      setUpTestingEnvironment(cwd, suffix: '.cache');

      File(path.join(Directory.current.path, 'mason.yaml'))
        ..writeAsStringSync('''bricks:
  app_icon:
    path: ../../bricks/app_icon
''');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test('clear removes .mason/brick.json', () async {
      final expectedBrickJsonPath = path.join(
        Directory.current.path,
        '.mason',
        'bricks.json',
      );

      final getResult = await commandRunner.run(['get']);
      expect(getResult, equals(ExitCode.success.code));
      expect(File(expectedBrickJsonPath).existsSync(), isTrue);

      final cacheClearResult = await commandRunner.run(['cache', 'clear']);
      expect(cacheClearResult, equals(ExitCode.success.code));
      expect(File(expectedBrickJsonPath).existsSync(), isFalse);
    });

    test('clear --force removes .mason/brick.json and warns user', () async {
      final expectedBrickJsonPath = path.join(
        Directory.current.path,
        '.mason',
        'bricks.json',
      );

      final getResult = await commandRunner.run(['get']);
      expect(getResult, equals(ExitCode.success.code));
      expect(File(expectedBrickJsonPath).existsSync(), isTrue);

      final cacheClearResult = await commandRunner.run(
        ['cache', 'clear', '--force'],
      );
      expect(cacheClearResult, equals(ExitCode.success.code));
      expect(File(expectedBrickJsonPath).existsSync(), isFalse);
      verify(
        logger.warn('using --force\nI sure hope you know what you are doing.'),
      ).called(1);
    });
  });
}
