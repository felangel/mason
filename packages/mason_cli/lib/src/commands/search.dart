import 'package:mason/mason.dart' hide packageVersion, Brick;
import 'package:mason_api/mason_api.dart';
import 'package:mason_cli/src/command.dart';

/// {@template logout_command}
/// `mason search` command which searches registered bricks on `brickhub.dev`.
/// {@endtemplate}
class SearchCommand extends MasonCommand {
  /// {@macro logout_command}
  SearchCommand({Logger? logger, MasonApi? masonApi})
      : _masonApi = masonApi ?? MasonApi(),
        super(logger: logger);

  final MasonApi _masonApi;

  @override
  final String description = 'Search registered bricks on brickhub.dev.';

  @override
  final String name = 'search';

  @override
  Future<int> run() async {
    final query = results.rest.join(' ');
    final searchProgress =
        logger.progress('Searching "$query" on brickhub.dev.');
    try {
      final results = await _masonApi.search(query: query);
      if (results.isEmpty) {
        searchProgress.complete('No bricks found.');
      } else {
        searchProgress.complete(
          'Found ${results.length} brick${results.length > 1 ? 's' : ''}.',
        );

        for (final brick in results) {
          logger
            ..success('${brick.name} (v${brick.version})')
            ..info('  ${brick.description}\n');
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
