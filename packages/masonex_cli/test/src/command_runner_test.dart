// ignore_for_file: no_adjacent_strings_in_list
import 'package:args/command_runner.dart';
import 'package:masonex/masonex.dart' hide packageVersion;
import 'package:masonex/masonex.dart' as masonex;
import 'package:masonex_cli/src/command_runner.dart';
import 'package:masonex_cli/src/version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockPubUpdater extends Mock implements PubUpdater {}

const expectedUsage = [
  '🧱  masonex • lay the foundation!\n'
      '\n'
      'Usage: masonex <command> [arguments]\n'
      '\n'
      'Global options:\n'
      '-h, --help       Print this usage information.\n'
      '    --version    Print the current version.\n'
      '\n'
      'Available commands:\n'
      '  add        Adds a brick from a local or remote source.\n'
      '  bundle     Generates a bundle from a brick template.\n'
      '  cache      Interact with masonex cache.\n'
      '  get        Gets all bricks in the nearest masonex.yaml.\n'
      '  init       Initialize masonex in the current directory.\n'
      '  list       Lists installed bricks.\n'
      '  login      Log into brickhub.dev.\n'
      '  logout     Log out of brickhub.dev.\n'
      '  make       Generate code using an existing brick template.\n'
      '  new        Creates a new brick template.\n'
      '  publish    Publish the current brick to brickhub.dev.\n'
      '  remove     Removes a brick.\n'
      '  search     Search published bricks on brickhub.dev.\n'
      '  unbundle   Generates a brick template from a bundle.\n'
      '  update     Update masonex.\n'
      '  upgrade    Upgrade bricks to their latest versions.\n'
      '\n'
      'Run "masonex help <command>" for more information about a command.'
];

const latestVersion = '0.0.0';
final changelogLink = lightCyan.wrap(
  styleUnderlined.wrap(
    link(
      uri: Uri.parse(
        'https://github.com/felangel/masonex/releases/tag/masonex_cli-v$latestVersion',
      ),
    ),
  ),
);
final updateMessage = '''
${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
${lightYellow.wrap('Changelog:')} $changelogLink
Run ${cyan.wrap('masonex update')} to update''';

void main() {
  group('MasonexCommandRunner', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late MasonexCommandRunner commandRunner;

    setUp(() {
      printLogs = [];
      logger = _MockLogger();
      pubUpdater = _MockPubUpdater();

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      commandRunner = MasonexCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
    });

    test('can be instantiated without an explicit logger instance', () {
      final commandRunner = MasonexCommandRunner();
      expect(commandRunner, isNotNull);
    });

    group('run', () {
      test('prompts for update when newer version exists', () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenAnswer((_) async => latestVersion);
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(() => logger.info(updateMessage)).called(1);
      });

      test('handles pub update errors gracefully', () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenThrow(Exception('oops'));

        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verifyNever(() => logger.info(updateMessage));
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

      test(
        'handles no command',
        overridePrint(() async {
          final result = await commandRunner.run([]);
          expect(printLogs, equals(expectedUsage));
          expect(result, equals(ExitCode.success.code));
        }),
      );

      test('handles completion', () async {
        final result = await commandRunner.run(['completion']);
        verifyNever(() => logger.info(any()));
        verifyNever(() => logger.err(any()));
        verifyNever(() => logger.warn(any()));
        verifyNever(() => logger.write(any()));
        verifyNever(() => logger.success(any()));
        verifyNever(() => logger.detail(any()));

        expect(result, equals(ExitCode.success.code));
      });

      group('--help', () {
        test(
          'outputs usage',
          overridePrint(() async {
            final result = await commandRunner.run(['--help']);
            expect(printLogs, equals(expectedUsage));
            expect(result, equals(ExitCode.success.code));

            printLogs.clear();

            final resultAbbr = await commandRunner.run(['-h']);
            expect(printLogs, equals(expectedUsage));
            expect(resultAbbr, equals(ExitCode.success.code));
          }),
        );
      });

      group('--version', () {
        test('outputs current versions', () async {
          final result = await commandRunner.run(['--version']);
          expect(result, equals(ExitCode.success.code));
          verify(
            () => logger.info(
              '''
masonex_cli $packageVersion • command-line interface
masonex ${masonex.packageVersion} • core templating engine''',
            ),
          ).called(1);
        });
      });
    });
  });
}
