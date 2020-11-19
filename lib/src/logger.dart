import 'dart:async';

import 'dart:io';
import 'package:io/ansi.dart';

/// A basic Logger which wraps [print] and applies various styles.
class Logger {
  static const List<String> _progressAnimation = [
    '⠋',
    '⠙',
    '⠹',
    '⠸',
    '⠼',
    '⠴',
    '⠦',
    '⠧',
    '⠇',
    '⠏'
  ];

  final _stopwatch = Stopwatch();
  Timer _timer;
  int _index = 0;

  /// Prints basic message.
  void info(String message) => print(message);

  /// Prints progress message.
  Function progress(String message) {
    _stopwatch
      ..reset()
      ..start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      _index++;
      final char = _progressAnimation[_index % _progressAnimation.length];
      stdout.write(
        '''${lightGreen.wrap('\b${'\b' * (message.length + 4)}$char')} $message...''',
      );
    });
    return () {
      _stopwatch.stop();
      final time =
          (_stopwatch.elapsed.inMilliseconds / 1000.0).toStringAsFixed(1);
      stdout.write(
        '''${lightGreen.wrap('\b${'\b' * (message.length + 4)}✓')} $message... (${time}ms)\n''',
      );
      _timer?.cancel();
    };
  }

  /// Prints error message.
  void err(String message) => print(lightRed.wrap(message));

  /// Prints alert message.
  void alert(String message) => print(lightCyan.wrap(styleBold.wrap(message)));

  /// Prints success message.
  void success(String message) => print(lightGreen.wrap(message));

  /// Prompts user and returns response.
  String prompt(String message) {
    stdout.write('$message');
    return stdin.readLineSync();
  }
}
