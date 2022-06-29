import 'dart:async';

import 'package:mason_logger/mason_logger.dart';
import 'package:universal_io/io.dart';

/// {@template progress}
/// A class that can be used to display progress information to the user.
/// {@endtemplate}
class Progress {
  /// {@macro progress}
  Progress(
    this._message,
    this._stdout,
    this._stderr,
  ) : _stopwatch = Stopwatch() {
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

  final Stdout _stderr;

  final Stdout _stdout;

  final Stopwatch _stopwatch;

  late final Timer _timer;

  String _message;
  String _messageTime = '';

  int _index = 0;

  /// End the progress and mark it as completed.
  @Deprecated('Please use [Progress.complete] instead.')
  void call([String? update]) {
    return complete(update);
  }

  /// End the progress and mark it as completed.
  void complete([String? update]) {
    _stopwatch.stop();
    _stdout.write(
      '''$_clearLn${lightGreen.wrap('✓')} ${update ?? _message} $_time\n''',
    );
    _timer.cancel();
  }

  /// End the progress and mark it as failed.
  void fail([String? update]) {
    _timer.cancel();
    _stderr.write('$_clearLn${red.wrap('✗')} ${update ?? _message} $_time\n');
    _stopwatch.stop();
  }

  /// Update the progress message.
  void update([String? update]) {
    if (update != null) _message = update;
    _messageTime = ' $_time';
  }

  /// Cancel the progress and remove the written line.
  void cancel() {
    _timer.cancel();
    _stdout.write(_clearLn);
    _stopwatch.stop();
  }

  void _onTimer(Timer _) {
    _index++;
    final char = _progressAnimation[_index % _progressAnimation.length];
    _stdout.write(
      '''${lightGreen.wrap('$_clearMessageLength$char')} $_message$_messageTime...''',
    );
  }

  String get _clearMessageLength {
    final length = _message.length + _messageTime.length + 4;
    return '\b${'\b' * length}';
  }

  String get _clearLn => '$_clearMessageLength\u001b[2K';

  String get _time {
    final _elapsed = _stopwatch.elapsed.inMilliseconds / 1000.0;
    return '''${darkGray.wrap('(${_elapsed.toStringAsFixed(1)}s)')}''';
  }
}
