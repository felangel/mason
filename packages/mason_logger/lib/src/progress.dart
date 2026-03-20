part of 'mason_logger.dart';

/// {@template progress_options}
/// An object containing configuration for a [Progress] instance.
/// {@endtemplate}
class ProgressOptions {
  /// {@macro progress_options}
  const ProgressOptions({
    this.animation = const ProgressAnimation(),
    this.trailing = '...',
  });

  /// The progress animation configuration.
  final ProgressAnimation animation;

  /// The trailing string following progress messages.
  /// Defaults to "..."
  final String trailing;
}

/// {@template progress_animation}
/// An object which contains configuration for the animation
/// of a [Progress] instance.
/// {@endtemplate}
class ProgressAnimation {
  /// {@macro progress_animation}
  const ProgressAnimation({
    this.frames = _defaultFrames,
    this.interval = _defaultInterval,
  });

  static const _defaultInterval = Duration(milliseconds: 80);

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
    '⠏',
  ];

  /// The list of animation frames.
  final List<String> frames;

  /// The interval at which new frames are produced.
  /// In other words, the amount of time spent showing a single frame.
  /// Defaults to 80ms per frame.
  final Duration interval;
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
      _write('$prefix$_message${_options.trailing}');
      return;
    }

    _timer = Timer.periodic(options.animation.interval, _onTick);
  }

  static const _padding = 15;
  static const _disableLineWrap = '\x1b[?7l';
  static const _enableLineWrap = '\x1b[?7h';

  final ProgressOptions _options;

  final io.Stdout _stdout;

  final Level _level;

  final Stopwatch _stopwatch;

  Timer? _timer;

  String _message;

  int _index = 0;

  /// End the progress and mark it as a successful completion.
  ///
  /// See also:
  ///
  /// * [fail], to end the progress and mark it as failed.
  /// * [cancel], to cancel the progress entirely and remove the written line.
  void complete([String? update]) {
    _stopwatch.stop();
    _write(
      '''$_enableWrap$_clearLine${lightGreen.wrap('✓')} ${update ?? _message} $_time\n''',
    );
    _timer?.cancel();
  }

  /// End the progress and mark it as failed.
  ///
  /// See also:
  ///
  /// * [complete], to end the progress and mark it as a successful completion.
  /// * [cancel], to cancel the progress entirely and remove the written line.
  void fail([String? update]) {
    _timer?.cancel();
    _write(
      '$_enableWrap$_clearLine${red.wrap('✗')} ${update ?? _message} $_time\n',
    );
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

  int get _terminalColumns {
    if (!_stdout.hasTerminal) return 80;
    return _stdout.terminalColumns;
  }

  String get _clampedMessage {
    final width = max(_terminalColumns - _padding, _padding);
    if (_message.length > width) return _message.substring(0, width);
    return _message;
  }

  String get _clearLine {
    if (!_stdout.hasTerminal) return '\r';
    return '\u001b[2K' // clear current line
        '\r'; // bring cursor to the start of the current line
  }

  String get _disableWrap {
    if (!_stdout.hasTerminal) return '';
    return _disableLineWrap;
  }

  String get _enableWrap {
    if (!_stdout.hasTerminal) return '';
    return _enableLineWrap;
  }

  void _onTick(Timer? _) {
    _index++;
    final frames = _options.animation.frames;
    final char = frames.isEmpty ? '' : frames[_index % frames.length];
    final prefix = char.isEmpty ? char : '${lightGreen.wrap(char)} ';
    _write(
      '''$_disableWrap$_clearLine$prefix$_clampedMessage${_options.trailing} $_time''',
    );
  }

  void _write(String object) {
    if (_level.index > Level.info.index) return;
    _stdout.write(object);
  }

  String get _time {
    final elapsedTime = _stopwatch.elapsed.inMilliseconds;
    final displayInMilliseconds = elapsedTime < 100;
    final time = displayInMilliseconds ? elapsedTime : elapsedTime / 1000;
    final formattedTime =
        displayInMilliseconds ? '${time}ms' : '${time.toStringAsFixed(1)}s';
    return '${darkGray.wrap('($formattedTime)')}';
  }
}
