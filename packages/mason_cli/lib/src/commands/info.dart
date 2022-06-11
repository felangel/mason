import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';

/// {@template info_command}
/// `mason info` command which shows detailed info of the brick.
/// {@endtemplate}
class InfoCommand extends MasonCommand {
  /// {@macro info_command}
  InfoCommand({Logger? logger}) : super(logger: logger) {
    argParser.addOption(
      'format',
      defaultsTo: 'console',
      help: 'Output format: console (default), json.',
    );
  }

  @override
  final String description = 'Shows detailed info of a brick.';

  @override
  final String name = 'info';

  @override
  Future<int> run() async {
    if (results.rest.isEmpty) usageException('brick name is required.');

    final name = results.rest.first;
    final brick = bricks.firstWhereOrNull((b) => b.name == name);

    if (brick == null) {
      logger.err('$name brick not found.');
      return ExitCode.data.code;
    }

    final outputFormat = results['format'] as String;
    switch (outputFormat) {
      case 'console':
        _printConsole(logger, brick);
        break;
      case 'json':
        _printJson(logger, brick);
        break;
      default:
        usageException('$outputFormat is not supported.');
    }
    return ExitCode.success.code;
  }
}

void _printConsole(Logger logger, BrickYaml brick) {
  logger
    ..info('Name: ${brick.name}')
    ..info('Version: ${brick.version}')
    ..info('Description: ${brick.description}');
}

void _printJson(Logger logger, BrickYaml brick) {
  logger.info(jsonEncode(brick.toJson()));
}
