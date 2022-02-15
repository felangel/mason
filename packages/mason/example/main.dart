import 'dart:io';

import 'package:mason/mason.dart';

Future<void> main() async {
  final brick = Brick.git(
    const GitPath(
      'https://github.com/felangel/mason.git',
      path: 'bricks/greeting',
    ),
  );
  final generator = await MasonGenerator.fromBrick(brick);
  final target = DirectoryGeneratorTarget(Directory.current);
  await generator.generate(target, vars: <String, dynamic>{'name': 'Dash'});
}
