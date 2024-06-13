import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  if (args.length != 2) return;
  final workingDirectory = args.first;
  final name = args.last;
  final brick = Brick.path(path.join('test', 'fixtures', 'hooks'));
  final generator = await MasonGenerator.fromBrick(brick);
  final target = DirectoryGeneratorTarget(Directory(workingDirectory));
  final vars = {'name': name};
  await generator.hooks.preGen(vars: vars, workingDirectory: workingDirectory);
  await generator.generate(target, vars: vars);
  await generator.hooks.postGen(vars: vars, workingDirectory: workingDirectory);
}
