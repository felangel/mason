import 'dart:math';

import 'package:mason/mason.dart';

const colors = [
  'Red',
  'Green',
  'Blue',
  'Yellow',
  'Cyan',
  'Magenta',
  'Pink',
  'White',
  'Black',
];

Future<void> run(HookContext context) async {
  final progress = context.logger.progress('Generating a random color');
  await Future<void>.delayed(Duration(seconds: 1));
  progress.complete('Generated');
  final randomSeed = Random().nextInt(colors.length);
  context.vars['favorite_color'] = colors[randomSeed];
}
