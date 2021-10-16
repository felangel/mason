// ignore_for_file: no_adjacent_strings_in_list
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/command_runner.dart';
import 'package:mason/src/io.dart';
import 'package:mason/src/version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import 'helpers/helpers.dart';

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

class FakeProcessResult extends Fake implements ProcessResult {}

const expectedUsage = [
  '⛏️  mason • lay the foundation!\n'
      '\n'
      'Usage: mason <command> [arguments]\n'
      '\n'
      'Global options:\n'
      '-h, --help       Print this usage information.\n'
      '    --version    Print the current version.\n'
      '\n'
      'Available commands:\n'
      '  add      Adds a brick from a local or remote source.\n'
      '  bundle   Generates a bundle from a brick template.\n'
      '  cache    Interact with mason cache.\n'
      '  get      Gets all bricks in the nearest mason.yaml.\n'
      '  init     Initialize mason in the current directory.\n'
      '  list     Lists all available bricks.\n'
      '  make     Generate code using an existing brick template.\n'
      '  new      Creates a new brick template.\n'
      '  remove   Removes a brick.\n'
      '\n'
      'Run "mason help <command>" for more information about a command.'
];

const latestVersion = '0.0.0';

final updatePrompt = '''
+------------------------------------------------------------------------------------+
|                                                                                    |
|                   ${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}                    |
|       ${lightYellow.wrap('Changelog:')} ${lightCyan.wrap('https://github.com/felangel/mason/releases/tag/v$latestVersion')}      |
|                                                                                    |
+------------------------------------------------------------------------------------+
''';

void main() {
  group('MasonCommandRunner', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late MasonCommandRunner commandRunner;

    setUp(() {
      printLogs = [];
      logger = MockLogger();
      pubUpdater = MockPubUpdater();

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);
      when(
        () => pubUpdater.update(packageName: packageName),
      ).thenAnswer((_) => Future.value(FakeProcessResult()));

      commandRunner = MasonCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
    });

    test('can be instantiated without an explicit logger instance', () {
      final commandRunner = MasonCommandRunner();
      expect(commandRunner, isNotNull);
    });

    group('run', () {
      test('prompts for update when newer version exists', () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenAnswer((_) async => latestVersion);

        when(() => logger.prompt(any())).thenReturn('n');

        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(() => logger.info(updatePrompt)).called(1);
        verify(
          () => logger.prompt('Would you like to update? (y/n) '),
        ).called(1);
      });

      test('handles pub update errors gracefully', () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenThrow(Exception('oops'));

        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verifyNever(() => logger.info(updatePrompt));
      });

      test('updates on "y" response when newer version exists', () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenAnswer((_) async => latestVersion);

        when(() => logger.prompt(any())).thenReturn('y');
        when(() => logger.progress(any())).thenReturn(([String? message]) {});

        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(() => logger.progress('Updating to $latestVersion')).called(1);
      });

      test('handles FormatException', () async {
        const exception = FormatException('oops!');
        var isFirstInvocation = true;
        when(() => logger.info(any())).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err(exception.message)).called(1);
        verify(() => logger.info(commandRunner.usage)).called(1);
      });

      test('handles UsageException', () async {
        final exception = UsageException('oops!', commandRunner.usage);
        var isFirstInvocation = true;
        when(() => logger.info(any())).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err(exception.message)).called(1);
        verify(() => logger.info(commandRunner.usage)).called(1);
      });

      test('handles no command', overridePrint(() async {
        final result = await commandRunner.run([]);
        expect(printLogs, equals(expectedUsage));
        expect(result, equals(ExitCode.success.code));
      }));

      group('--help', () {
        test('outputs usage', overridePrint(() async {
          final result = await commandRunner.run(['--help']);
          expect(printLogs, equals(expectedUsage));
          expect(result, equals(ExitCode.success.code));

          printLogs.clear();

          final resultAbbr = await commandRunner.run(['-h']);
          expect(printLogs, equals(expectedUsage));
          expect(resultAbbr, equals(ExitCode.success.code));
        }));
      });

      group('--version', () {
        test('outputs current version', () async {
          final result = await commandRunner.run(['--version']);
          expect(result, equals(ExitCode.success.code));
          verify(() => logger.info(packageVersion)).called(1);
        });
      });
    });
  });
}
