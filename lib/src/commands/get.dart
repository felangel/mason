import 'package:io/io.dart';
import 'package:mason/mason.dart';

import '../command.dart';

/// {@template get_command}
/// `mason get` command which gets all bricks.
/// {@endtemplate}
class GetCommand extends MasonCommand {
  /// {@macro get_command}
  GetCommand({Logger? logger}) : super(logger: logger) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      defaultsTo: false,
      help: 'Overwrites cached bricks',
    );
  }

  @override
  final String description = 'Gets all bricks.';

  @override
  final String name = 'get';

  @override
  Future<int> run() async {
    final getDone = logger.progress('getting bricks');
    final force = results['force'] == true;
    if (force) clearCache();
    if (masonYaml.bricks.values.isNotEmpty) {
      await Future.forEach(masonYaml.bricks.values, writeBrick);
      await flushCache();
    }
    getDone();
    return ExitCode.success.code;
  }
}
