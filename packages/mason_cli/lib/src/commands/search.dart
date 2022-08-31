import 'package:mason/mason.dart' hide packageVersion, Brick;
import 'package:mason_api/mason_api.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/command_runner.dart';
import 'package:path/path.dart' as path;

/// {@template logout_command}
/// `mason search` command which searches registered bricks on `brickhub.dev`.
/// {@endtemplate}
class SearchCommand extends MasonCommand {
  /// {@macro logout_command}
  SearchCommand({Logger? logger, MasonApi? masonApi})
      : _masonApi = masonApi ?? MasonApi(),
        super(logger: logger) {
    argParser.addFlag(
      'global',
      abbr: 'g',
      help: 'Search bricks globally',
    );
  }

  final MasonApi _masonApi;

  @override
  final String description = 'Search published bricks on brickhub.dev.';

  @override
  final String name = 'search';

  @override
  Future<int> run() async {
    if (results.rest.isEmpty) usageException('search term is required.');

    final query = results.rest.first;
    final isGlobalSearch = results['global'] == true;
    final searchProgress = logger.progress(
      isGlobalSearch
          ? 'Searching "$query" globally'
          : 'Searching "$query" on brickhub.dev',
    );

    try {
      if (isGlobalSearch) {
        final bricks = globalBricks;

        logger.info(path.dirname(globalMasonYamlFile.path));

        if (bricks.isEmpty) {
          logger.info('└── (empty)');
          return ExitCode.success.code;
        }

        final sortedBricks = [...bricks]..sort(
            (a, b) => a.name.compareTo(
              b.name,
            ),
          );

        final searchResults = sortedBricks.where(
          (brick) {
            final contains = brick.name.contains(query);
            return contains;
          },
        ).toList();

        searchProgress.complete(
          searchResults.isEmpty
              ? 'No bricks found.'
              : '''Found ${searchResults.length} brick${searchResults.length == 1 ? '' : 's'}.''',
        );

        final responce = logger.chooseOne(
          'Search results',
          choices: searchResults.map<String>((e) {
            return '${e.name} ${e.version} -> ${e.path}';
          }).toList(),
        );
        final name = responce.trim().split(' ')[0];

        logger.info('Selected $name brick');

        // TODO: Need to find a better way to call brick generation command.
        await MasonCommandRunner().run(['make', name]);
      } else {
        final results = await _masonApi.search(query: query);
        searchProgress.complete(
          results.isEmpty
              ? 'No bricks found.'
              : '''Found ${results.length} brick${results.length == 1 ? '' : 's'}.''',
        );
        logger.info('');

        for (final brick in results) {
          logger
            ..info(
              lightCyan.wrap(styleBold.wrap('${brick.name} v${brick.version}')),
            )
            ..info(brick.description)
            ..info('https://brickhub.dev/bricks/${brick.name}/${brick.version}')
            ..info(darkGray.wrap('-' * 80));
        }
      }

      return ExitCode.success.code;
    } catch (error) {
      searchProgress.fail();
      logger.err('$error');
      return ExitCode.software.code;
    }
  }
}
