import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

void main() async {
  final brick = Brick.path(path.join('test', 'fixtures', 'basic'));
  final generator = await MasonGenerator.fromBrick(brick);
  final target = DirectoryGeneratorTarget(
    Directory.systemTemp.createTempSync(),
  );
  await generator.hooks.preGen();
  await generator.generate(target);
  await generator.hooks.postGen();
}
