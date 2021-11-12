import 'dart:io';

void main() {
  final file = File('${Directory.current.path}/.pre_gen.txt');
  file.writeAsStringSync('pre_gen: {{name}}');
}
