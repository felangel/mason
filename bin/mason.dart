import 'dart:convert';
import 'dart:io';

import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mason/src/version.dart';

void main(List<String> args) async {
  parser..addCommand('build');

  Options options;
  try {
    options = parseOptions(args);
  } on FormatException catch (e) {
    print(lightRed.wrap(e.message));
    print('');
    print(_usage);
    exitCode = ExitCode.usage.code;
    return;
  }

  if (options.help) {
    print(lightCyan.wrap(styleBold.wrap(
      '⚒️ mason \u{2022} lay the foundation!',
    )));
    print(_usage);
    return;
  }

  if (options.version) {
    print('mason version: $packageVersion');
    return;
  }

  final command = options.command;

  if (command == null) {
    print(lightRed.wrap(
      "Specify a command: ${parser.commands.keys.join(', ')}",
    ));
    print('');
    print(_usage);
    exitCode = ExitCode.usage.code;
    return;
  }

  print(lightGreen.wrap('${'⚒️ building...'}'));
}

String get _usage {
  return '''
Usage: mason <command> [<args>]
${styleBold.wrap('Commands:')}
  build   build new component from a template
${styleBold.wrap('Arguments:')}
${_indent(parser.usage)}''';
}

String _indent(String input) =>
    LineSplitter.split(input).map((l) => '  $l'.trimRight()).join('\n');
