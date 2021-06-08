import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';

import '../command.dart';

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
    for (final brick in bricks) {
      logger.info('${styleBold.wrap(brick.name)} - ${brick.description}');
    }
    return ExitCode.success.code;
  }
}
