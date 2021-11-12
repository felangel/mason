import 'dart:io';

void main() {
  final file = File('.post_gen.txt');
  file.writeAsStringSync('post_gen: {{name}}');
}