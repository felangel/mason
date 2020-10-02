import 'dart:convert';
import 'dart:io' as io;
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

import 'logger.dart';
import 'options.dart';
import 'version.dart';

/// {@template mason_cli}
/// Mason CLI which helps you lay the foundation for your next project!
/// {@endtemplate}
class MasonCli {
  /// {@macro mason_cli}
  MasonCli(this.logger);

  /// [Logger] instance used to output information.
  final Logger logger;

  io.Directory _cwd;

  /// Return the current working directory.
  io.Directory get cwd => _cwd ?? io.Directory.current;

  /// An override for the directory to generate into; public for testing.
  set cwd(io.Directory value) => _cwd = value;

  /// Builds template based on supplied [options].
  Future<void> build(Options options) async {
    final dir = cwd;
    if (!await _isDirEmpty(dir)) {}

    if (options.template == null) {
      logger
        ..err('Specify a template')
        ..info('')
        ..info(usage);
      io.exitCode = ExitCode.usage.code;
      return;
    }

    logger.success('⚒️  ${'building ${options.template}'}');
  }

  /// Outputs information about CLI usage.
  void help() {
    logger
      ..alert('⚒️  mason \u{2022} lay the foundation!')
      ..info(usage);
  }

  /// Outputs CLI version information.
  void version() {
    logger.info('mason version: $packageVersion');
  }

  /// Outputs an error along with CLI Usage information.
  void unrecognized() {
    logger
      ..err("Specify a command: ${parser.commands.keys.join(', ')}")
      ..info('')
      ..info(usage);
    io.exitCode = ExitCode.usage.code;
  }

  /// Returns true if the given directory does not contain non-symlinked,
  /// non-hidden subdirectories.
  static Future<bool> _isDirEmpty(io.Directory dir) async {
    final isHiddenDir = (io.FileSystemEntity dir) {
      return path.basename(dir.path).startsWith('.');
    };

    return dir
        .list(followLinks: false)
        .where((entity) => entity is io.Directory)
        .where((entity) => !isHiddenDir(entity))
        .isEmpty;
  }

  /// Returns CLI Usage information.
  static String get usage {
    return '''
Usage: mason <command> [<args>]
${styleBold.wrap('Commands:')}
  build   build new component from a template
${styleBold.wrap('Arguments:')}
${_indent(parser.usage)}''';
  }
}

String _indent(String input) =>
    LineSplitter.split(input).map((l) => '  $l'.trimRight()).join('\n');
