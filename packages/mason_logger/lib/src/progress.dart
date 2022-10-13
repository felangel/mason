part of 'mason_logger.dart';

/// {@template progress_options}
/// An object containing configuration for a [Progress] instance.
/// {@endtemplate}
class ProgressOptions {
  /// {@macro progress_options}
  const ProgressOptions({this.animation = const ProgressAnimation()});

  /// The progress animation configuration.
  final ProgressAnimation animation;
}

/// {@template progress_animation}
/// An object which contains configuration for the animation
/// of a [Progress] instance.
/// {@endtemplate}
class ProgressAnimation {
  /// {@macro progress_animation}
  const ProgressAnimation({this.frames = _defaultProgressAnimationFrames});

  static const List<String> _defaultProgressAnimationFrames = [
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

  /// A list of animation frames.
  final List<String> frames;
}

/// {@template progress}
/// A class that can be used to display progress information to the user.
/// {@endtemplate}
class Progress {
  /// {@macro progress}
  Progress._(
    this._message,
    this._stdout,
    this._level, {
    ProgressOptions options = const ProgressOptions(),
  })  : _stopwatch = Stopwatch(),
        _options = options {
    _stopwatch
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(milliseconds: 80), _onTick);
  }

  final ProgressOptions _options;

  final io.Stdout _stdout;

  final Level _level;

  final Stopwatch _stopwatch;

  late final Timer _timer;

  String _message;

  int _index = 0;

  /// End the progress and mark it as completed.
  void complete([String? update]) {
    _stopwatch.stop();
    _write(
      '''$_clearLn${lightGreen.wrap('✓')} ${update ?? _message} $_time\n''',
    );
    _timer.cancel();
  }

  /// End the progress and mark it as failed.
  void fail([String? update]) {
    _timer.cancel();
    _write('$_clearLn${red.wrap('✗')} ${update ?? _message} $_time\n');
    _stopwatch.stop();
  }

  /// Update the progress message.
  void update(String update) {
    _write(_clearLn);
    _message = update;
    _onTick(_timer);
  }

  /// Cancel the progress and remove the written line.
  void cancel() {
    _timer.cancel();
    _write(_clearLn);
    _stopwatch.stop();
  }

  void _onTick(Timer _) {
    _index++;
    final frames = _options.animation.frames;
    final char = frames[_index % frames.length];
    _write(
      '''${lightGreen.wrap('$_clearMessageLength$char')} $_message... $_time''',
    );
  }

  void _write(Object? object) {
    if (_level.index > Level.info.index) return;
    _stdout.write(object);
  }

  String get _clearMessageLength {
    final length = _message.length + 4 + _time.length;
    return '\b${'\b' * length}';
  }

  String get _clearLn => '$_clearMessageLength\u001b[2K';

  String get _time {
    final elapsedTime = _stopwatch.elapsed.inMilliseconds;
    final displayInMilliseconds = elapsedTime < 100;
    final time = displayInMilliseconds ? elapsedTime : elapsedTime / 1000;
    final formattedTime = displayInMilliseconds
        ? '${time.toString()}ms'
        : '${time.toStringAsFixed(1)}s';
    return '${darkGray.wrap('($formattedTime)')}';
  }
}
