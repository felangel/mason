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

  final _queue = <String?>[];

  final _stopwatch = Stopwatch();
  Timer? _timer;
  int _index = 0;

  /// Flushes internal message queue.
  void flush([Function(String?)? print]) {
    final writeln = print ?? info;
    for (final message in _queue) {
      writeln(message);
    }
    _queue.clear();
  }

  /// Writes info message to stdout.
  void info(String? message) => stdout.writeln(message);

  /// Writes delayed message to stdout.
  void delayed(String? message) => _queue.add(message);

  /// Writes progress message to stdout.
  void Function([String? update]) progress(String message) {
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
    return ([String? update]) {
      _stopwatch.stop();
      final time =
          (_stopwatch.elapsed.inMilliseconds / 1000.0).toStringAsFixed(1);
      stdout.write(
        '''${lightGreen.wrap('\b${'\b' * (message.length + 4)}✓')} ${update ?? message} (${time}ms)\n''',
      );
      _timer?.cancel();
    };
  }

  /// Writes error message to stdout.
  void err(String? message) => stdout.writeln(lightRed.wrap(message));

  /// Writes alert message to stdout.
  void alert(String? message) {
    stdout.writeln(lightCyan.wrap(styleBold.wrap(message)));
  }

  /// Writes detail message to stdout.
  void detail(String? message) => stdout.writeln(darkGray.wrap(message));

  /// Writes warning message to stdout.
  void warn(String? message) {
    stdout.writeln(yellow.wrap(styleBold.wrap('[WARN] $message')));
  }

  /// Writes success message to stdout.
  void success(String? message) => stdout.writeln(lightGreen.wrap(message));

  /// Prompts user and returns response.
  String prompt(String? message) {
    stdout.write('$message');
    return stdin.readLineSync() ?? '';
  }
}
