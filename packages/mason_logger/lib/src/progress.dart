import 'dart:async';

import 'package:mason_logger/mason_logger.dart';
import 'package:universal_io/io.dart';

/// {@template progress}
/// A class that can be used to display progress information to the user.
/// {@endtemplate}
class Progress {
  /// {@macro progress}
  Progress(this._message, this._stdout) : _stopwatch = Stopwatch() {
    _stopwatch
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(milliseconds: 80), _onTimer);
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

  final Stopwatch _stopwatch;

  late final Timer _timer;

  final String _message;

  int _index = 0;

  /// End the progress and mark it as completed.
  @Deprecated('Please use [Progress.complete] instead.')
  void call([String? update]) {
    return complete(update);
  }

  /// End the progress and mark it as completed.
  void complete([String? update]) {
    _stopwatch.stop();
    final time =
        (_stopwatch.elapsed.inMilliseconds / 1000.0).toStringAsFixed(1);
    _stdout.write(
      '''\b${'\b' * (_message.length + 4)}\u001b[2K${lightGreen.wrap('✓')} ${update ?? _message} ${darkGray.wrap('(${time}s)')}\n''',
    );
    _timer.cancel();
  }

  /// End the progress and mark it as failed.
  void fail([String? update]) {
    _timer.cancel();
    final time =
        (_stopwatch.elapsed.inMilliseconds / 1000.0).toStringAsFixed(1);
    _stdout.write(
      '''\b${'\b' * (_message.length + 4)}\u001b[2K${red.wrap('✗')} ${update ?? _message} ${darkGray.wrap('(${time}s)')}\n''',
    );
    _stopwatch.stop();
  }

  /// Cancel the progress and remove the written line.
  void cancel() {
    _timer.cancel();
    _stdout.write('\b${'\b' * (_message.length + 4)}');
    _stopwatch.stop();
  }

  void _onTimer(Timer _) {
    _index++;
    final char = _progressAnimation[_index % _progressAnimation.length];
    _stdout.write(
      '''${lightGreen.wrap('\b${'\b' * (_message.length + 4)}$char')} $_message...''',
    );
  }
}
