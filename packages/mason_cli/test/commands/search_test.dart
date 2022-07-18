import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart' hide Brick;
import 'package:mason_api/mason_api.dart';
import 'package:mason_cli/src/commands/commands.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockUser extends Mock implements User {}

class MockLogger extends Mock implements Logger {}

class MockMasonApi extends Mock implements MasonApi {}

class MockProgress extends Mock implements Progress {}

class MockArgResults extends Mock implements ArgResults {}

void main() {
  group('SearchCommand', () {
    late Logger logger;
    late MasonApi masonApi;
    late SearchCommand searchCommand;
    late ArgResults argResults;
    late BrickSearchResult brick;

    setUp(() {
      brick = BrickSearchResult(
        name: 'name',
        description: 'description',
        publisher: 'publisher',
        version: 'version',
        createdAt: DateTime(0, 0, 0),
        downloads: 42,
      );
      logger = MockLogger();
      masonApi = MockMasonApi();
      argResults = MockArgResults();
      searchCommand = SearchCommand(logger: logger, masonApi: masonApi)
        ..testArgResults = argResults;

      when(() => logger.progress(any())).thenReturn(MockProgress());
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
      final progress = MockProgress();
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
      expect(progressDoneCalls, equals(['No bricks found.']));
    });

    test('exits with code 0 when one result is shown', () async {
      final progress = MockProgress();
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
    });

    test('exits with code 0 when more than one result is shown', () async {
      final progress = MockProgress();
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
    });

    test('exits with code 70 when exception occurs', () async {
      final progress = MockProgress();
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
    });
  });
}
