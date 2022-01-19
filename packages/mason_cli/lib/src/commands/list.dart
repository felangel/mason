import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:path/path.dart' as path;

/// {@template list_command}
/// `mason list` command which lists all available bricks.
/// {@endtemplate}
class ListCommand extends MasonCommand {
  /// {@macro list_command}
  ListCommand({Logger? logger}) : super(logger: logger) {
    argParser.addFlag(
      'global',
      abbr: 'g',
      help: 'Lists globally installed bricks.',
    );
  }

  @override
  final String description = 'Lists installed bricks.';

  @override
  final String name = 'list';

  @override
  List<String> get aliases => ['ls'];

  @override
  Future<int> run() async {
    final isGlobal = results['global'] == true;
    final bricks = isGlobal ? globalBricks : localBricks;

    logger.info(isGlobal ? path.dirname(globalMasonYamlFile.path) : cwd.path);

    if (bricks.isEmpty) {
      logger.info('└── (empty)');
      return ExitCode.success.code;
    }

    final sortedBricks = [...bricks]..sort((a, b) => a.name.compareTo(b.name));

    for (var i = 0; i < sortedBricks.length; i++) {
      final brick = sortedBricks.elementAt(i);
      final prefix = i == sortedBricks.length - 1 ? '└──' : '├──';

      logger.info(
        '$prefix ${styleBold.wrap(brick.name)} - ${brick.description}',
      );
    }

    return ExitCode.success.code;
  }
}
