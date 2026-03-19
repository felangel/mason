import 'dart:io';
import 'dart:math';

import 'package:masonex/masonex.dart' hide Brick, packageVersion;
import 'package:masonex_api/masonex_api.dart';
import 'package:masonex_cli/src/command.dart';
import 'package:masonex_cli/src/command_runner.dart';

/// {@template logout_command}
/// `masonex search` command which searches registered bricks on `brickhub.dev`.
/// {@endtemplate}
class SearchCommand extends MasonexCommand {
  /// {@macro logout_command}
  SearchCommand({super.logger, MasonexApiBuilder? masonexApiBuilder})
      : _masonexApiBuilder = masonexApiBuilder ?? MasonexApi.new;

  final MasonexApiBuilder _masonexApiBuilder;

  @override
  final String description = 'Search published bricks on brickhub.dev.';

  @override
  final String name = 'search';

  @override
  Future<int> run() async {
    if (results.rest.isEmpty) usageException('search term is required.');

    final query = results.rest.first;
    final searchProgress = logger.progress(
      'Searching "$query" on brickhub.dev',
    );

    final masonexApi = _masonexApiBuilder();
    try {
      final results = await masonexApi.search(query: query);
      searchProgress.complete(
        results.isEmpty
            ? 'No bricks found.'
            : '''Found ${results.length} brick${results.length == 1 ? '' : 's'}.''',
      );

      logger.info('');

      for (final brick in results) {
        final brickLink = styleUnderlined.wrap(
          link(
            uri: Uri.parse(
              'https://brickhub.dev/bricks/${brick.name}/${brick.version}',
            ),
          ),
        );
        logger
          ..info(
            lightCyan.wrap(styleBold.wrap('${brick.name} v${brick.version}')),
          )
          ..info(brick.description)
          ..info(brickLink)
          ..info(darkGray.wrap('-' * _separatorLength()));
      }
      return ExitCode.success.code;
    } catch (error) {
      searchProgress.fail();
      logger.err('$error');
      return ExitCode.software.code;
    } finally {
      masonexApi.close();
    }
  }
}

int _separatorLength() {
  const maxSeparatorLength = 80;
  try {
    return min(stdout.terminalColumns, maxSeparatorLength);
  } catch (_) {
    return maxSeparatorLength;
  }
}
