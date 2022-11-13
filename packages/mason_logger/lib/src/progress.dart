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
  const ProgressAnimation({this.frames = _defaultFrames});

  static const _defaultFrames = [
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

  /// The list of animation frames.
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

    // The animation is only shown when it would be meaningful.
    // Do not animate if the stdio type is not a terminal.
    if (!_stdout.hasTerminal) {
      final frames = _options.animation.frames;
      final char = frames.isEmpty ? '' : frames.first;
      final prefix = char.isEmpty ? char : '${lightGreen.wrap(char)} ';
      _write('$prefix$_message...');
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 80), _onTick);
  }

  final ProgressOptions _options;

  final io.Stdout _stdout;

  final Level _level;

  final Stopwatch _stopwatch;

  Timer? _timer;

  String _message;

  int _index = 0;

  /// End the progress and mark it as completed.
  void complete([String? update]) {
    _stopwatch.stop();
    _write(
      '''$_clearLine${lightGreen.wrap('✓')} ${update ?? _message} $_time\n''',
    );
    _timer?.cancel();
  }

  /// End the progress and mark it as failed.
  void fail([String? update]) {
    _timer?.cancel();
    _write('$_clearLine${red.wrap('✗')} ${update ?? _message} $_time\n');
    _stopwatch.stop();
  }

  /// Update the progress message.
  void update(String update) {
    if (_timer != null) _write(_clearLine);
    _message = update;
    _onTick(_timer);
  }

  /// Cancel the progress and remove the written line.
  void cancel() {
    _timer?.cancel();
    _write(_clearLine);
    _stopwatch.stop();
  }

  String get _clearLine {
    return '\u001b[2K' // clear current line
        '\r'; // bring cursor to the start of the current line
  }

  void _onTick(Timer? _) {
    _index++;
    final frames = _options.animation.frames;
    final char = frames.isEmpty ? '' : frames[_index % frames.length];
    final prefix = char.isEmpty ? char : '${lightGreen.wrap(char)} ';

    _write('$_clearLine$prefix$_message... $_time');
  }

  void _write(String object) {
    if (_level.index > Level.info.index) return;
    _stdout.write(object);
  }

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
