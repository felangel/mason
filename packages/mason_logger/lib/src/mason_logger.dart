import 'dart:async';

import 'package:mason_logger/src/io.dart';
import 'package:meta/meta.dart';
import 'package:universal_io/io.dart' as io;

const _asyncRunZoned = runZoned;

// TODO(felangel): remove when IOOverrides stdout/stdin is available in stable, https://github.com/dart-lang/sdk/commit/0d6c343196ea216cfb1eecc9e4f5c4cdedcdd52f
/// This class facilitates overriding [io.stdout] and [io.stdin].
/// It should be extended by another class in client code with overrides
/// that construct a custom implementation.
@visibleForTesting
abstract class StdioOverrides {
  static final _token = Object();

  /// Returns the current [StdioOverrides] instance.
  ///
  /// This will return `null` if the current [Zone] does not contain
  /// any [StdioOverrides].
  ///
  /// See also:
  /// * [StdioOverrides.runZoned] to provide [StdioOverrides]
  /// in a fresh [Zone].
  ///
  static StdioOverrides? get current {
    return Zone.current[_token] as StdioOverrides?;
  }

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  static R runZoned<R>(
    R Function() body, {
    io.Stdout Function()? stdout,
    io.Stdin Function()? stdin,
  }) {
    final overrides = _StdioOverridesScope(stdout, stdin);
    return _asyncRunZoned(body, zoneValues: {_token: overrides});
  }

  /// The [io.Stdout] that will be used within the current [Zone].
  io.Stdout get stdout => io.stdout;

  /// The [io.Stdin] that will be used within the current [Zone].
  io.Stdin get stdin => io.stdin;
}

class _StdioOverridesScope extends StdioOverrides {
  _StdioOverridesScope(this._stdout, this._stdin);

  final StdioOverrides? _previous = StdioOverrides.current;
  final io.Stdout Function()? _stdout;
  final io.Stdin Function()? _stdin;

  @override
  io.Stdout get stdout {
    return _stdout?.call() ?? _previous?.stdout ?? super.stdout;
  }

  @override
  io.Stdin get stdin {
    return _stdin?.call() ?? _previous?.stdin ?? super.stdin;
  }
}

/// A basic Logger which wraps `stdio` and applies various styles.
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
  final StdioOverrides? _overrides = StdioOverrides.current;

  io.Stdout get _stdout => _overrides?.stdout ?? io.stdout;
  io.Stdin get _stdin => _overrides?.stdin ?? io.stdin;

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
  void info(String? message) => _stdout.writeln(message);

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
      _stdout.write(
        '''${lightGreen.wrap('\b${'\b' * (message.length + 4)}$char')} $message...''',
      );
    });
    return ([String? update]) {
      _stopwatch.stop();
      final time =
          (_stopwatch.elapsed.inMilliseconds / 1000.0).toStringAsFixed(1);
      _stdout.write(
        '''\b${'\b' * (message.length + 4)}\u001b[2K${lightGreen.wrap('✓')} ${update ?? message} ${darkGray.wrap('(${time}s)')}\n''',
      );
      _timer?.cancel();
    };
  }

  /// Writes error message to stdout.
  void err(String? message) => _stdout.writeln(lightRed.wrap(message));

  /// Writes alert message to stdout.
  void alert(String? message) {
    _stdout.writeln(lightCyan.wrap(styleBold.wrap(message)));
  }

  /// Writes detail message to stdout.
  void detail(String? message) => _stdout.writeln(darkGray.wrap(message));

  /// Writes warning message to stdout.
  void warn(String? message, {String tag = 'WARN'}) {
    _stdout.writeln(yellow.wrap(styleBold.wrap('[$tag] $message')));
  }

  /// Writes success message to stdout.
  void success(String? message) => _stdout.writeln(lightGreen.wrap(message));

  /// Prompts user and returns response.
  String prompt(String? message, {Object? defaultValue}) {
    final hasDefault = defaultValue != null && '$defaultValue'.isNotEmpty;
    final _defaultValue = hasDefault ? '$defaultValue' : '';
    final suffix = hasDefault ? ' ${darkGray.wrap('($_defaultValue)')}' : '';
    final _message = '$message$suffix ';
    _stdout.write(_message);
    final input = _stdin.readLineSync()?.trim();
    final response = input == null || input.isEmpty ? _defaultValue : input;
    _stdout.writeln(
      '\x1b[A\u001B[2K$_message${styleDim.wrap(lightCyan.wrap(response))}',
    );
    return response;
  }

  /// Prompts user with a yes/no question.
  bool confirm(String? message, {bool defaultValue = false}) {
    final suffix = ' ${darkGray.wrap('(${defaultValue.toYesNo()})')}';
    final _message = '$message$suffix ';
    _stdout.write(_message);
    final input = _stdin.readLineSync()?.trim();
    final response = input == null || input.isEmpty
        ? defaultValue
        : input.toBoolean() ?? defaultValue;
    _stdout.writeln(
      '''\x1b[A\u001B[2K$_message${styleDim.wrap(lightCyan.wrap(response ? 'Yes' : 'No'))}''',
    );
    return response;
  }
}

extension on bool {
  String toYesNo() {
    return this == true ? 'Y/n' : 'y/N';
  }
}

extension on String {
  bool? toBoolean() {
    switch (toLowerCase()) {
      case 'y':
      case 'yea':
      case 'yeah':
      case 'yep':
      case 'yes':
      case 'yup':
        return true;
      case 'n':
      case 'no':
      case 'nope':
        return false;
      default:
        return null;
    }
  }
}
