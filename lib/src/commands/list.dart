import 'package:mason/mason.dart';

import '../command.dart';
import '../io.dart';

/// {@template list_command}
/// `mason list` command which lists all available bricks.
/// {@endtemplate}
class ListCommand extends MasonCommand {
  /// {@macro list_command}
  ListCommand({Logger? logger}) : super(logger: logger);

  @override
  final String description = 'Lists all available bricks.';

  @override
  final String name = 'list';

  @override
  List<String> get aliases => ['ls'];

  @override
  Future<int> run() async {
    if (bricks.isEmpty) {
      logger.info('(empty)');
      return ExitCode.success.code;
    }

    for (final brick in bricks) {
      logger.info('${styleBold.wrap(brick.name)} - ${brick.description}');
    }
    return ExitCode.success.code;
  }
}
