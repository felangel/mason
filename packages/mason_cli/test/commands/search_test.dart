import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart' hide Brick;
import 'package:mason_api/mason_api.dart';
import 'package:mason_cli/src/commands/commands.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockMasonApi extends Mock implements MasonApi {}

class _MockProgress extends Mock implements Progress {}

class _MockArgResults extends Mock implements ArgResults {}

class _MockStdout extends Mock implements Stdout {}

void main() {
  group('SearchCommand', () {
    late Logger logger;
    late MasonApi masonApi;
    late SearchCommand searchCommand;
    late ArgResults argResults;
    late BrickSearchResult brick;
    late Stdout stdout;

    setUp(() {
      brick = BrickSearchResult(
        name: 'name',
        description: 'description',
        publisher: 'publisher',
        version: 'version',
        createdAt: DateTime(0, 0, 0),
        downloads: 42,
      );
      logger = _MockLogger();
      masonApi = _MockMasonApi();
      argResults = _MockArgResults();
      stdout = _MockStdout();
      searchCommand = SearchCommand(
        logger: logger,
        masonApiBuilder: ({Uri? hostedUri}) => masonApi,
      )..testArgResults = argResults;

      when(() => logger.progress(any())).thenReturn(_MockProgress());
    });

    test('can be instantiated without any parameters', () {
      expect(SearchCommand.new, returnsNormally);
    });

    test('throws UsageException when search term is missing', () async {
      when(() => argResults.rest).thenReturn([]);
      CommandRunner<int>('example', 'description').addCommand(searchCommand);
      expect(() => searchCommand.run(), throwsA(isA<UsageException>()));
    });

    test('exits with code 0 when no results are shown', () async {
      final progress = _MockProgress();
      final progressDoneCalls = <String?>[];

      when(() => progress.complete(any())).thenAnswer((invocation) {
        final update = invocation.positionalArguments[0] as String?;
        progressDoneCalls.add(update);
      });
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => argResults.rest).thenReturn(['query']);
      when(
        () => masonApi.search(query: 'query'),
      ).thenAnswer((_) async => const []);
      final result = await searchCommand.run();

      expect(result, ExitCode.success.code);
      verify(
        () => logger.progress('Searching "query" on brickhub.dev'),
      ).called(1);
      verify(() => masonApi.close()).called(1);
      expect(progressDoneCalls, equals(['No bricks found.']));
    });

    test('exits with code 0 when one result is shown', () async {
      final progress = _MockProgress();
      final progressDoneCalls = <String?>[];

      when(() => progress.complete(any())).thenAnswer((invocation) {
        final update = invocation.positionalArguments[0] as String?;
        progressDoneCalls.add(update);
      });
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => argResults.rest).thenReturn(['query']);
      when(
        () => masonApi.search(query: 'query'),
      ).thenAnswer((_) async => [brick]);

      final result = await searchCommand.run();

      expect(result, ExitCode.success.code);

      verify(
        () => logger.progress('Searching "query" on brickhub.dev'),
      ).called(1);
      expect(progressDoneCalls, equals(['Found 1 brick.']));
      verify(
        () => logger.info(
          lightCyan.wrap(styleBold.wrap('${brick.name} v${brick.version}')),
        ),
      ).called(1);
      verify(() => logger.info(brick.description)).called(1);
      verify(() => masonApi.close()).called(1);
    });

    test('exits with code 0 when more than one result is shown', () async {
      final progress = _MockProgress();
      final progressDoneCalls = <String?>[];

      when(() => progress.complete(any())).thenAnswer((invocation) {
        final update = invocation.positionalArguments[0] as String?;
        progressDoneCalls.add(update);
      });
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => argResults.rest).thenReturn(['query']);
      when(
        () => masonApi.search(query: 'query'),
      ).thenAnswer((_) async => [brick, brick]);

      final result = await searchCommand.run();

      expect(result, ExitCode.success.code);
      expect(progressDoneCalls, equals(['Found 2 bricks.']));
      verify(
        () => logger.progress('Searching "query" on brickhub.dev'),
      ).called(1);
      verify(
        () => logger.info(
          lightCyan.wrap(styleBold.wrap('${brick.name} v${brick.version}')),
        ),
      ).called(2);
      verify(() => logger.info(brick.description)).called(2);
      verify(() => masonApi.close()).called(1);
    });

    test('exits with code 70 when exception occurs', () async {
      final progress = _MockProgress();
      final progressDoneCalls = <String?>[];
      final exception = Exception('oops');

      when(() => progress.complete(any())).thenAnswer((invocation) {
        final update = invocation.positionalArguments[0] as String?;
        progressDoneCalls.add(update);
      });
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => argResults.rest).thenReturn(['query']);
      when(() => masonApi.search(query: 'query')).thenThrow(exception);

      final result = await searchCommand.run();

      expect(result, equals(ExitCode.software.code));
      verify(
        () => logger.progress('Searching "query" on brickhub.dev'),
      ).called(1);
      verify(() => logger.err('$exception')).called(1);
      verify(() => masonApi.close()).called(1);
    });

    test('separator length is 80 when terminal is not available', () async {
      final progress = _MockProgress();
      when(() => progress.complete(any())).thenAnswer((_) {});
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => argResults.rest).thenReturn(['query']);
      when(
        () => masonApi.search(query: 'query'),
      ).thenAnswer((_) async => [brick]);

      final result = await searchCommand.run();

      expect(result, ExitCode.success.code);

      verify(() => logger.info(darkGray.wrap('-' * 80))).called(1);
    });

    test('separator length is 80 when terminalColumns > 80', () async {
      final progress = _MockProgress();
      when(() => progress.complete(any())).thenAnswer((_) {});
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => argResults.rest).thenReturn(['query']);
      when(
        () => masonApi.search(query: 'query'),
      ).thenAnswer((_) async => [brick]);
      when(() => stdout.hasTerminal).thenReturn(true);
      when(() => stdout.terminalColumns).thenReturn(100);
      when(() => stdout.supportsAnsiEscapes).thenReturn(true);
      final result = await IOOverrides.runZoned(
        () => searchCommand.run(),
        stdout: () => stdout,
      );

      expect(result, ExitCode.success.code);

      verify(() => logger.info(darkGray.wrap('-' * 80))).called(1);
    });

    test(
        'separator length is terminalColumns '
        'when terminalColumns < 80', () async {
      final progress = _MockProgress();
      when(() => progress.complete(any())).thenAnswer((_) {});
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => argResults.rest).thenReturn(['query']);
      when(
        () => masonApi.search(query: 'query'),
      ).thenAnswer((_) async => [brick]);
      when(() => stdout.hasTerminal).thenReturn(true);
      when(() => stdout.terminalColumns).thenReturn(42);
      when(() => stdout.supportsAnsiEscapes).thenReturn(true);
      final result = await IOOverrides.runZoned(
        () => searchCommand.run(),
        stdout: () => stdout,
      );

      expect(result, ExitCode.success.code);

      verify(() => logger.info(darkGray.wrap('-' * 42))).called(1);
    });
  });
}
