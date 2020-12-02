import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import 'commands/commands.dart';
import 'exception.dart';
import 'logger.dart';
import 'version.dart';

/// {@template mason_command_runner}
/// A [CommandRunner] for the Mason CLI.
/// {@endtemplate}
class MasonCommandRunner extends CommandRunner<int> {
  /// {@macro mason_command_runner}
  MasonCommandRunner({Logger logger})
      : _logger = logger ?? Logger(),
        super('mason', '⛏️  mason \u{2022} lay the foundation!') {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the current version.',
    );
    try {
      addCommand(InitCommand());
      addCommand(GetCommand());
      addCommand(MakeCommand());
      addCommand(NewCommand());
    } on MasonException catch (e) {
      _logger.err(e.message);
      exit(ExitCode.usage.code);
    }
  }

  final Logger _logger;

  ArgResults _argResults;

  /// The top-level options parsed by the command runner.
  ArgResults get argResults => _argResults;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      _argResults = parse(args);
      return await runCommand(_argResults) ?? ExitCode.success.code;
    } on FormatException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      _logger.info('mason version: $packageVersion');
      return ExitCode.success.code;
    }
    return super.runCommand(topLevelResults);
  }
}
