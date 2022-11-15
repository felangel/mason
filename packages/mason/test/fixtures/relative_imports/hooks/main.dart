import 'dart:io';
import 'package:mason/mason.dart';

void foo(HookContext context) {
  File('.pre_gen.txt').writeAsStringSync('pre_gen: ${context.vars['name']}');
}