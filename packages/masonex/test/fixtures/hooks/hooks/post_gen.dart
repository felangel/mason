import 'dart:io';
import 'package:masonex/masonex.dart';

void run(HookContext context) {
  final file = File('.post_gen.txt');
  file.writeAsStringSync('post_gen: ${context.vars['name']}');
}
