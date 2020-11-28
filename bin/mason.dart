import 'dart:io' show exit;

import 'package:args/command_runner.dart';
import 'package:io/io.dart' as io;
import 'package:io/io.dart';
import 'package:mason/src/commands/commands.dart';
import 'package:mason/src/logger.dart';
import 'package:mason/src/version.dart';

void main(List<String> args) async {
  final logger = Logger();
  final masonCli =
      CommandRunner<int>('mason', '⛏️  mason \u{2022} lay the foundation!')
        ..argParser.addFlag(
          'version',
          negatable: false,
          help: 'Print the current version.',
        )
        ..addCommand(InitCommand())
        ..addCommand(MakeCommand())
        ..addCommand(NewCommand());

  try {
    final globalArgs = masonCli.argParser.parse(args);
    if (globalArgs['version'] == true) {
      logger.info('mason version: $packageVersion');
      exit(ExitCode.success.code);
    }
    await masonCli.run(args);
  } on FormatException catch (e) {
    logger
      ..err(e.message)
      ..info('')
      ..info(masonCli.usage);
    exit(io.ExitCode.usage.code);
  } on UsageException catch (e) {
    logger
      ..err(e.message)
      ..info('')
      ..info(masonCli.usage);
    exit(io.ExitCode.usage.code);
  }
  exit(ExitCode.success.code);
}
