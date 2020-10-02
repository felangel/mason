import 'dart:io';

import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/logger.dart';

void main(List<String> args) async {
  final logger = Logger();
  final cli = MasonCli(logger);

  parser..addCommand('build');

  Options options;
  try {
    options = parseOptions(args);
  } on FormatException catch (e) {
    logger
      ..err(e.message)
      ..info('')
      ..info(MasonCli.usage);
    exitCode = ExitCode.usage.code;
    return;
  }

  if (options.help) return cli.help();
  if (options.version) return cli.version();

  final command = options.command;
  switch (command?.name) {
    case 'build':
      return cli.build(options);
    default:
      return cli.unrecognized();
  }
}
