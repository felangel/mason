import 'dart:async';

import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:universal_io/io.dart';

/// {@template progress}
/// A class that can be used to display progress information to the user.
/// {@endtemplate}
class Progress {
  /// {@macro progress}
  @internal
  Progress(
    this._message,
    this._stdout,
    // Stdin stdin,
    this._level,
  ) : _stopwatch = Stopwatch() {
    _stopwatch
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(milliseconds: 80), _onTimer);

    // // TODO(wolfen): Check if supports ANSI?
    // _stdout.write('\x1b[6n'); // Request cursor position.

    // stdin
    //   ..echoMode = false
    //   ..lineMode = false;

    // final regex = RegExp(r'\x1b\[(\d+);(\d+)R');
    // final event = <String>[];
    // Match? match;
    // while ((match = regex.firstMatch(event.join())) == null) {
    //   event.add(String.fromCharCode(stdin.readByteSync()));
    // }
    // _row = int.parse(match!.group(1)!);
    // _column = int.parse(match.group(2)!);
    // stdin
    //   ..echoMode = true
    //   ..lineMode = true;
  }

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

  final Stdout _stdout;

  final Level _level;

  final Stopwatch _stopwatch;

  late final Timer _timer;

  // late final int _row;
  // late final int _column;

  String _message;

  int _index = 0;

  /// End the progress and mark it as completed.
  void complete([String? update]) {
    _stopwatch.stop();
    _write('$_clearLn${lightGreen.wrap('✓')} ${update ?? _message} $_time');
    _timer.cancel();
  }

  /// End the progress and mark it as failed.
  void fail([String? update]) {
    _timer.cancel();
    _write('$_clearLn${red.wrap('✗')} ${update ?? _message} $_time');
    _stopwatch.stop();
  }

  /// Update the progress message.
  void update(String update) {
    _write(_clearLn);
    _message = update;
    _onTimer(_timer);
  }

  /// Cancel the progress and remove the written line.
  void cancel() {
    // TODO(wolfen): Should we keep the written line?
    _timer.cancel();
    _write(_clearLn);
    _stopwatch.stop();
  }

  void _onTimer(Timer _) {
    _index++;
    final char = _progressAnimation[_index % _progressAnimation.length];
    _write('${lightGreen.wrap(char)} $_message... $_time');
  }

  void _write(Object? object) {
    if (_level.index > Level.info.index) return;
    _stdout
      ..write('\x1b[25l') // Hide cursor
      ..write('\x1b7'); // Save cursor position
    for (var i = 0; i < 1; i++) {
      _stdout.write('\x1bM'); // Move cursor up
    }
    // ..write('\x1b[$_row;${_column}H') // Move cursor to the correct position
    _stdout
      ..write('$object') // Write the message
      ..write('\x1b8') // Restore cursor position
      ..write('\x1b[28h'); // Show cursor
  }

  String get _clearMessageLength {
    final length = _message.length + 4 + _time.length;
    return '\b${'\b' * length}';
  }

  String get _clearLn => '$_clearMessageLength\u001b[2K';

  String get _time {
    final elapsed = _stopwatch.elapsed.inMilliseconds / 1000.0;
    return '''${darkGray.wrap('(${elapsed.toStringAsFixed(1)}s)')}''';
  }
}
