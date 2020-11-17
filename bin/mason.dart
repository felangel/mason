import 'dart:io';

import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/logger.dart';

void main(List<String> args) async {
  final logger = Logger();
  final cli = MasonCli(logger);
  final extraArgs = <String>[];

  parser..addCommand('build');

  Options options;
  try {
    options = parseOptions(args);
    final indexOfRest = args.indexOf('--');
    if (indexOfRest != -1) {
      extraArgs.addAll(args.sublist(indexOfRest + 1));
    }
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
      return cli.build(options, extraArgs);
    default:
      return cli.unrecognized();
  }
}
