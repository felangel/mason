import 'dart:io' show exit;

import 'package:args/command_runner.dart';
import 'package:io/io.dart' as io;
import 'package:mason/src/commands/commands.dart';
import 'package:mason/src/logger.dart';
import 'package:mason/src/version.dart';

void main(List<String> args) {
  final logger = Logger();
  final masonCli =
      CommandRunner<void>('mason', '⛏️  mason \u{2022} lay the foundation!')
        ..argParser.addFlag(
          'version',
          negatable: false,
          help: 'Print the current version.',
        )
        ..addCommand(BuildCommand(logger));

  final globalArgs = masonCli.argParser.parse(args);
  if (globalArgs['version'] == true) {
    return logger.info('mason version: $packageVersion');
  }

  masonCli
    ..run(args).catchError((dynamic error) {
      if (error is! UsageException) throw error;
      logger
        ..err((error as UsageException).message)
        ..info('')
        ..info(masonCli.usage);
      exit(io.ExitCode.usage.code);
    });
}
