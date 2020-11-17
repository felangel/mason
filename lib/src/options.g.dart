// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'options.dart';

// **************************************************************************
// CliGenerator
// **************************************************************************

Options _$parseOptionsResult(ArgResults result) => Options(
    template: result['template'] as String,
    help: result['help'] as bool,
    version: result['version'] as bool,
    command: result.command);

ArgParser _$populateOptionsParser(ArgParser parser) => parser
  ..addOption('template', abbr: 't', help: 'template yaml path')
  ..addFlag('help',
      abbr: 'h', help: 'Prints usage information.', negatable: false)
  ..addFlag('version', help: 'Print the current version.', negatable: false);

final _$parserForOptions = _$populateOptionsParser(ArgParser());

Options parseOptions(List<String> args) {
  final result = _$parserForOptions.parse(args);
  return _$parseOptionsResult(result);
}
