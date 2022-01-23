import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

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

void main(List<String> args, SendPort port) {
  final vars = json.decode(args.first);
  final randomSeed = Random().nextInt(colors.length);
  port.send({...vars, 'favorite_color': colors[randomSeed]});
}
