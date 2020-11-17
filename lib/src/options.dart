import 'package:build_cli_annotations/build_cli_annotations.dart';

part 'options.g.dart';

/// An `ArgParser` which handles parsing the options.
ArgParser get parser => _$parserForOptions;

/// {@template options}
/// Dart object which represents the CLI options.
/// {@endtemplate}
@CliOptions()
class Options {
  /// {@macro options}
  const Options({
    this.template,
    this.help,
    this.version,
    this.command,
  });

  /// Path to template.yaml
  @CliOption(
    name: 'template',
    abbr: 't',
    help: 'template yaml path',
  )
  final String template;

  /// Prints usage information.
  @CliOption(
    abbr: 'h',
    negatable: false,
    help: 'Prints usage information.',
  )
  final bool help;

  /// Prints the current CLI version.
  @CliOption(
    negatable: false,
    help: 'Print the current version.',
  )
  final bool version;

  /// The results of parsing a series of command line arguments using
  /// [ArgParser.parse()].
  final ArgResults command;
}
