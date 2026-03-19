import 'dart:io';
import 'package:masonex/masonex.dart';

void preGen(HookContext context) {
  File('.pre_gen.txt').writeAsStringSync('pre_gen: ${context.vars['name']}');
}

void postGen(HookContext context) {
  File('.post_gen.txt').writeAsStringSync('post_gen: ${context.vars['name']}');
}
