part of 'mason_logger.dart';

final RegExp _stripRegex = RegExp(
  [
    r'[\u001B\u009B][[\]()#;?]*(?:(?:(?:[a-zA-Z\d]*(?:;[-a-zA-Z\d\/#&.:=?%@~_]*)*)?\u0007)',
    r'(?:(?:\d{1,4}(?:;\\d{0,4})*)?[\dA-PR-TZcf-ntqry=><~]))'
  ].join('|'),
);

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

  String? _prevMessage;

  /// End the progress and mark it as completed.
  void complete([String? update]) {
    _stopwatch.stop();
    _write(
      '''$_clearPrevMessage${lightGreen.wrap('✓')} ${update ?? _message} $_time\n''',
    );
    _timer?.cancel();
  }

  /// End the progress and mark it as failed.
  void fail([String? update]) {
    _timer?.cancel();
    _write('$_clearPrevMessage${red.wrap('✗')} ${update ?? _message} $_time\n');
    _stopwatch.stop();
  }

  /// Update the progress message.
  void update(String update) {
    if (_timer != null) _write(_clearPrevMessage);
    _message = update;
    _onTick(_timer);
  }

  /// Cancel the progress and remove the previous message.
  void cancel() {
    _timer?.cancel();
    _write(_clearPrevMessage);
    _stopwatch.stop();
  }

  String get _clearPrevMessage {
    if (_stdout.hasTerminal) {
      final prevMessageLength = _strip(_prevMessage ?? '').length;
      final maxLineLength = _stdout.terminalColumns;
      final linesToClear = (prevMessageLength / maxLineLength).ceil();

      return <String>[
        for (var i = 0; i < linesToClear; i++) ...[
          '\u001b[2K', // clear current line
          if (i == linesToClear - 1) ...[
            '\r', // bring cursor to the start of the current line
          ] else ...[
            '\u001b[1A', // move cursor up one line
          ]
        ],
      ].join(); // for each line of previous message
    }

    return '\u001b[2K' // clear current line
        '\r'; // bring cursor to the start of the current line
  }

  /// Removes any ANSI styling from [input].
  String _strip(String input) {
    return input.replaceAll(_stripRegex, '');
  }

  void _onTick(Timer? _) {
    _index++;
    final frames = _options.animation.frames;
    final char = frames.isEmpty ? '' : frames[_index % frames.length];
    final prefix = char.isEmpty ? char : '${lightGreen.wrap(char)} ';

    _write('$_clearPrevMessage$prefix$_message... $_time');
  }

  void _write(String object) {
    if (_level.index > Level.info.index) return;
    _prevMessage = object;
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
