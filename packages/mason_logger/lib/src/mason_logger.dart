import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:mason_logger/mason_logger.dart';

part 'progress.dart';

/// {@template logger}
/// A basic Logger which wraps `stdio` and applies various styles.
/// {@endtemplate}
class Logger {
  /// {@macro logger}
  Logger({
    this.level = Level.info,
    this.progressOptions = const ProgressOptions(),
  });

  /// The current log level for this logger.
  Level level;

  /// The progress options for the logger instance.
  ProgressOptions progressOptions;

  final _queue = <String?>[];
  final io.IOOverrides? _overrides = io.IOOverrides.current;

  final _jKey = [106];
  final _kKey = [107];
  final _upKey = [27, 91, 65];
  final _downKey = [27, 91, 66];
  final _enterKey = [13];
  final _returnKey = [10];
  final _spaceKey = [32];

  io.Stdout get _stdout => _overrides?.stdout ?? io.stdout;
  io.Stdin get _stdin => _overrides?.stdin ?? io.stdin;
  io.Stdout get _stderr => _overrides?.stderr ?? io.stderr;

  /// Flushes internal message queue.
  void flush([Function(String?)? print]) {
    final writeln = print ?? info;
    for (final message in _queue) {
      writeln(message);
    }
    _queue.clear();
  }

  /// Write message via `stdout.write`.
  void write(String? message) => _stdout.write(message);

  /// Writes info message to stdout.
  void info(String? message) {
    if (level.index > Level.info.index) return;
    _stdout.writeln(message);
  }

  /// Writes delayed message to stdout.
  void delayed(String? message) => _queue.add(message);

  /// Writes progress message to stdout.
  /// Optionally provide [options] to override the current
  /// [ProgressOptions] for the generated [Progress].
  Progress progress(String message, {ProgressOptions? options}) {
    return Progress._(
      message,
      _stdout,
      level,
      options: options ?? progressOptions,
    );
  }

  /// Writes error message to stderr.
  void err(String? message) {
    if (level.index > Level.error.index) return;
    _stderr.writeln(lightRed.wrap(message));
  }

  /// Writes alert message to stdout.
  void alert(String? message) {
    if (level.index > Level.critical.index) return;
    _stderr.writeln(backgroundRed.wrap(styleBold.wrap(white.wrap(message))));
  }

  /// Writes detail message to stdout.
  void detail(String? message) {
    if (level.index > Level.debug.index) return;
    _stdout.writeln(darkGray.wrap(message));
  }

  /// Writes warning message to stderr.
  void warn(String? message, {String tag = 'WARN'}) {
    if (level.index > Level.warning.index) return;
    _stderr.writeln(yellow.wrap(styleBold.wrap('[$tag] $message')));
  }

  /// Writes success message to stdout.
  void success(String? message) {
    if (level.index > Level.info.index) return;
    _stdout.writeln(lightGreen.wrap(message));
  }

  /// Prompts user and returns response.
  /// Provide a default value via [defaultValue].
  /// Set [hidden] to `true` if you want to hide user input for sensitive info.
  String prompt(String? message, {Object? defaultValue, bool hidden = false}) {
    final hasDefault = defaultValue != null && '$defaultValue'.isNotEmpty;
    final _defaultValue = hasDefault ? '$defaultValue' : '';
    final suffix = hasDefault ? ' ${darkGray.wrap('($_defaultValue)')}' : '';
    final _message = '$message$suffix ';
    _stdout.write(_message);
    final input =
        hidden ? _readLineHiddenSync() : _stdin.readLineSync()?.trim();
    final response = input == null || input.isEmpty ? _defaultValue : input;
    final lines = _message.split('\n').length - 1;
    final prefix =
        lines > 1 ? '\x1b[A\u001B[2K\u001B[${lines}A' : '\x1b[A\u001B[2K';
    _stdout.writeln(
      '''$prefix$_message${styleDim.wrap(lightCyan.wrap(hidden ? '******' : response))}''',
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
    final lines = _message.split('\n').length - 1;
    final prefix =
        lines > 1 ? '\x1b[A\u001B[2K\u001B[${lines}A' : '\x1b[A\u001B[2K';
    _stdout.writeln(
      '''$prefix$_message${styleDim.wrap(lightCyan.wrap(response ? 'Yes' : 'No'))}''',
    );
    return response;
  }

  /// Prompts user with [message] to choose one value from the provided
  /// [choices].
  ///
  /// An optional [defaultValue] can be specified.
  /// The [defaultValue] must be one of the provided [choices].
  T chooseOne<T extends Object?>(
    String? message, {
    required List<T> choices,
    T? defaultValue,
    String Function(T choice)? display,
  }) {
    final _display = display ?? (value) => '$value';
    final hasDefault =
        defaultValue != null && _display(defaultValue).isNotEmpty;
    var index = hasDefault ? choices.indexOf(defaultValue) : 0;

    void writeChoices() {
      _stdout
        // save cursor
        ..write('\x1b7')
        // hide cursor
        ..write('\x1b[?25l')
        ..writeln('$message');

      for (final choice in choices) {
        final isCurrent = choices.indexOf(choice) == index;
        final checkBox = isCurrent ? lightCyan.wrap('◉') : '◯';
        if (isCurrent) {
          _stdout
            ..write(green.wrap('❯'))
            ..write(' $checkBox  ${lightCyan.wrap(_display(choice))}');
        } else {
          _stdout
            ..write(' ')
            ..write(' $checkBox  ${_display(choice)}');
        }
        if (choices.last != choice) {
          _stdout.write('\n');
        }
      }
    }

    _stdin
      ..echoMode = false
      ..lineMode = false;

    writeChoices();

    final event = <int>[];
    T? result;
    while (result == null) {
      final byte = _stdin.readByteSync();
      if (event.length == 3) event.clear();
      event.add(byte);
      if (event.isOneOf([_upKey, _kKey])) {
        event.clear();
        index = (index - 1) % (choices.length);
      } else if (event.isOneOf([_downKey, _jKey])) {
        event.clear();
        index = (index + 1) % (choices.length);
      } else if (event.isOneOf([_enterKey, _returnKey, _spaceKey])) {
        _stdin
          ..lineMode = true
          ..echoMode = true;

        _stdout
          // restore cursor
          ..write('\x1b8')
          // clear to end of screen
          ..write('\x1b[J')
          // show cursor
          ..write('\x1b[?25h')
          ..write('$message ')
          ..writeln(styleDim.wrap(lightCyan.wrap(_display(choices[index]))));

        result = choices[index];
        break;
      }

      // restore cursor
      _stdout.write('\x1b8');
      writeChoices();
    }

    return result!;
  }

  /// Prompts user with [message] to choose zero or more values
  /// from the provided [choices].
  ///
  /// An optional list of [defaultValues] can be specified.
  /// The [defaultValues] must be one of the provided [choices].
  List<T> chooseAny<T extends Object?>(
    String? message, {
    required List<T> choices,
    List<T>? defaultValues,
    String Function(T choice)? display,
  }) {
    final _display = display ?? (value) => '$value';
    final hasDefaults = defaultValues != null && defaultValues.isNotEmpty;
    final selections = hasDefaults
        ? defaultValues.map((value) => choices.indexOf(value)).toSet()
        : <int>{};
    var index = 0;

    void writeChoices() {
      _stdout
        // save cursor
        ..write('\x1b7')
        // hide cursor
        ..write('\x1b[?25l')
        ..writeln('$message');

      for (final choice in choices) {
        final choiceIndex = choices.indexOf(choice);
        final isCurrent = choiceIndex == index;
        final isSelected = selections.contains(choiceIndex);
        final checkBox = isSelected ? lightCyan.wrap('◉') : '◯';
        if (isCurrent) {
          _stdout
            ..write(green.wrap('❯'))
            ..write(' $checkBox  ${lightCyan.wrap(_display(choice))}');
        } else {
          _stdout
            ..write(' ')
            ..write(' $checkBox  ${_display(choice)}');
        }
        if (choices.last != choice) {
          _stdout.write('\n');
        }
      }
    }

    _stdin
      ..echoMode = false
      ..lineMode = false;

    writeChoices();

    final event = <int>[];
    List<T>? results;
    while (results == null) {
      final byte = _stdin.readByteSync();
      if (event.length == 3) event.clear();
      event.add(byte);
      if (event.isOneOf([_upKey, _kKey])) {
        event.clear();
        index = (index - 1) % (choices.length);
      } else if (event.isOneOf([_downKey, _jKey])) {
        event.clear();
        index = (index + 1) % (choices.length);
      } else if (event.isOneOf([_spaceKey])) {
        event.clear();
        selections.contains(index)
            ? selections.remove(index)
            : selections.add(index);
      } else if (event.isOneOf([_enterKey, _returnKey])) {
        _stdin
          ..lineMode = true
          ..echoMode = true;

        results = selections.map((index) => choices[index]).toList();

        _stdout
          // restore cursor
          ..write('\x1b8')
          // clear to end of screen
          ..write('\x1b[J')
          // show cursor
          ..write('\x1b[?25h')
          ..write('$message ')
          ..writeln(styleDim.wrap(lightCyan.wrap('$results')));

        break;
      }

      // restore cursor
      _stdout.write('\x1b8');
      writeChoices();
    }

    return results;
  }

  String _readLineHiddenSync() {
    const lineFeed = 10;
    const carriageReturn = 13;
    const delete = 127;
    final value = <int>[];

    try {
      _stdin
        ..echoMode = false
        ..lineMode = false;
      int char;
      do {
        char = _stdin.readByteSync();
        if (char != lineFeed && char != carriageReturn) {
          final shouldDelete = char == delete && value.isNotEmpty;
          shouldDelete ? value.removeLast() : value.add(char);
        }
      } while (char != lineFeed && char != carriageReturn);
    } finally {
      _stdin
        ..lineMode = true
        ..echoMode = true;
    }
    _stdout.writeln();
    return utf8.decode(value);
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

extension on Iterable<int> {
  bool isOneOf(Iterable<Iterable<int>> keys) =>
      keys.any((key) => key.every(contains));
}
