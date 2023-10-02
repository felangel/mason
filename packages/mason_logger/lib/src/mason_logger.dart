import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:mason_logger/mason_logger.dart';
import 'package:mason_logger/src/ffi/terminal.dart';
import 'package:mason_logger/src/io.dart';
import 'package:mason_logger/src/terminal_overrides.dart';

part 'progress.dart';

/// Type definition for a function which accepts a log message
/// and returns a styled version of that message.
///
/// Generally, [AnsiCode] values are used to generate a [LogStyle].
///
/// ```dart
/// final alertStyle = (m) => backgroundRed.wrap(styleBold.wrap(white.wrap(m)));
/// ```
typedef LogStyle = String? Function(String? message);

String? _detailStyle(String? m) => darkGray.wrap(m);
String? _infoStyle(String? m) => m;
String? _errStyle(String? m) => lightRed.wrap(m);
String? _warnStyle(String? m) => yellow.wrap(styleBold.wrap(m));
String? _alertStyle(String? m) =>
    backgroundRed.wrap(styleBold.wrap(white.wrap(m)));
String? _successStyle(String? m) => lightGreen.wrap(m);

/// {@template log_theme}
/// A theme object which contains styles for all log message types.
/// {@endtemplate}
class LogTheme {
  /// {@macro log_theme}
  const LogTheme({
    LogStyle? detail,
    LogStyle? info,
    LogStyle? err,
    LogStyle? warn,
    LogStyle? alert,
    LogStyle? success,
  })  : detail = detail ?? _detailStyle,
        info = info ?? _infoStyle,
        err = err ?? _errStyle,
        warn = warn ?? _warnStyle,
        alert = alert ?? _alertStyle,
        success = success ?? _successStyle;

  /// The [LogStyle] used by [detail].
  final LogStyle detail;

  /// The [LogStyle] used by [info].
  final LogStyle info;

  /// The [LogStyle] used by [err].
  final LogStyle err;

  /// The [LogStyle] used by [warn].
  final LogStyle warn;

  /// The [LogStyle] used by [alert].
  final LogStyle alert;

  /// The [LogStyle] used by [success].
  final LogStyle success;
}

/// {@template logger}
/// A basic Logger which wraps `stdio` and applies various styles.
/// {@endtemplate}
class Logger {
  /// {@macro logger}
  Logger({
    this.theme = const LogTheme(),
    this.level = Level.info,
    this.progressOptions = const ProgressOptions(),
  });

  /// The current theme for this logger.
  final LogTheme theme;

  /// The current log level for this logger.
  Level level;

  /// The progress options for the logger instance.
  ProgressOptions progressOptions;

  final _queue = <String?>[];
  final io.IOOverrides? _overrides = io.IOOverrides.current;

  io.Stdout get _stdout => _overrides?.stdout ?? io.stdout;
  io.Stdin get _stdin => _overrides?.stdin ?? io.stdin;
  io.Stdout get _stderr => _overrides?.stderr ?? io.stderr;
  Never _exit(int code) => (TerminalOverrides.current?.exit ?? io.exit)(code);
  final _terminal = TerminalOverrides.current?.createTerminal() ?? Terminal();

  KeyStroke Function() get _readKey {
    return () {
      _terminal.enableRawMode();
      final key = TerminalOverrides.current?.readKey() ?? readKey();
      _terminal.disableRawMode();
      if (key.controlChar == ControlCharacter.ctrlC) _exit(130);
      return key;
    };
  }

  /// Flushes internal message queue.
  void flush([void Function(String?)? print]) {
    final writeln = print ?? info;
    for (final message in _queue) {
      writeln(message);
    }
    _queue.clear();
  }

  /// Write message via `stdout.write`.
  void write(String? message) => _stdout.write(message);

  /// Writes info message to stdout.
  void info(String? message, {LogStyle? style}) {
    if (level.index > Level.info.index) return;
    style ??= theme.info;
    _stdout.writeln(style.call(message) ?? message);
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
  void err(String? message, {LogStyle? style}) {
    if (level.index > Level.error.index) return;
    style ??= theme.err;
    _stderr.writeln(style(message));
  }

  /// Writes alert message to stdout.
  void alert(String? message, {LogStyle? style}) {
    if (level.index > Level.critical.index) return;
    style ??= theme.alert;
    _stderr.writeln(style(message));
  }

  /// Writes detail message to stdout.
  void detail(String? message, {LogStyle? style}) {
    if (level.index > Level.debug.index) return;
    style ??= theme.detail;
    _stdout.writeln(style(message));
  }

  /// Writes warning message to stderr.
  void warn(String? message, {String tag = 'WARN', LogStyle? style}) {
    if (level.index > Level.warning.index) return;
    final output = tag.isEmpty ? '$message' : '[$tag] $message';
    style ??= theme.warn;
    _stderr.writeln(style(output));
  }

  /// Writes success message to stdout.
  void success(String? message, {LogStyle? style}) {
    if (level.index > Level.info.index) return;
    style ??= theme.success;
    _stdout.writeln(style(message));
  }

  /// Prompts user and returns response.
  /// Provide a default value via [defaultValue].
  /// Set [hidden] to `true` if you want to hide user input for sensitive info.
  String prompt(String? message, {Object? defaultValue, bool hidden = false}) {
    final hasDefault = defaultValue != null && '$defaultValue'.isNotEmpty;
    final resolvedDefaultValue = hasDefault ? '$defaultValue' : '';
    final suffix =
        hasDefault ? ' ${darkGray.wrap('($resolvedDefaultValue)')}' : '';
    final resolvedMessage = '$message$suffix ';
    _stdout.write(resolvedMessage);
    final input =
        hidden ? _readLineHiddenSync() : _stdin.readLineSync()?.trim();
    final response =
        input == null || input.isEmpty ? resolvedDefaultValue : input;
    final lines = resolvedMessage.split('\n').length - 1;
    final prefix =
        lines > 1 ? '\x1b[A\u001B[2K\u001B[${lines}A' : '\x1b[A\u001B[2K';
    _stdout.writeln(
      '''$prefix$resolvedMessage${styleDim.wrap(lightCyan.wrap(hidden ? '******' : response))}''',
    );
    return response;
  }

  /// Prompts user for a free-form list of responses.
  List<String> promptAny(String? message, {String separator = ','}) {
    _stdin
      ..echoMode = false
      ..lineMode = false;

    final delimeter = '$separator ';
    var rawString = '';

    _stdout.write('$message ');

    while (true) {
      final key = _readKey();
      final isEnterOrReturnKey = key.controlChar == ControlCharacter.ctrlJ ||
          key.controlChar == ControlCharacter.ctrlM;
      final isDeleteOrBackspaceKey =
          key.controlChar == ControlCharacter.delete ||
              key.controlChar == ControlCharacter.backspace ||
              key.controlChar == ControlCharacter.ctrlH;

      if (isEnterOrReturnKey) break;

      if (isDeleteOrBackspaceKey) {
        if (rawString.isNotEmpty) {
          if (rawString.endsWith(delimeter)) {
            _stdout.write('\b\b\x1b[K');
            rawString = rawString.substring(0, rawString.length - 2);
          } else {
            _stdout.write('\b\x1b[K');
            rawString = rawString.substring(0, rawString.length - 1);
          }
        }
        continue;
      }

      if (key.char == separator) {
        _stdout.write(delimeter);
        rawString += delimeter;
      } else {
        _stdout.write(key.char);
        rawString += key.char;
      }
    }

    if (rawString.endsWith(delimeter)) {
      rawString = rawString.substring(0, rawString.length - 2);
    }

    final results = rawString.isEmpty ? <String>[] : rawString.split(delimeter);
    const clearLine = '\u001b[2K\r';
    _stdout.write(
      '$clearLine$message ${styleDim.wrap(lightCyan.wrap('$results'))}\n',
    );

    _stdin
      ..lineMode = true
      ..echoMode = true;
    return results;
  }

  /// Prompts user with a yes/no question.
  bool confirm(String? message, {bool defaultValue = false}) {
    final suffix = ' ${darkGray.wrap('(${defaultValue.toYesNo()})')}';
    final resolvedMessage = '$message$suffix ';
    _stdout.write(resolvedMessage);
    String? input;
    try {
      input = _stdin.readLineSync()?.trim();
    } on FormatException catch (_) {
      // FormatExceptions can occur due to utf8 decoding errors
      // so we treat them as the user pressing enter (e.g. use `defaultValue`).
      _stdout.writeln();
    }
    final response = input == null || input.isEmpty
        ? defaultValue
        : input.toBoolean() ?? defaultValue;
    final lines = resolvedMessage.split('\n').length - 1;
    final prefix =
        lines > 1 ? '\x1b[A\u001B[2K\u001B[${lines}A' : '\x1b[A\u001B[2K';
    _stdout.writeln(
      '''$prefix$resolvedMessage${styleDim.wrap(lightCyan.wrap(response ? 'Yes' : 'No'))}''',
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
    final resolvedDisplay = display ?? (value) => '$value';
    final hasDefault =
        defaultValue != null && resolvedDisplay(defaultValue).isNotEmpty;
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
            ..write(' $checkBox  ${lightCyan.wrap(resolvedDisplay(choice))}');
        } else {
          _stdout
            ..write(' ')
            ..write(' $checkBox  ${resolvedDisplay(choice)}');
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

    T? result;
    while (result == null) {
      final key = _readKey();
      final isArrowUpOrKKey =
          key.controlChar == ControlCharacter.arrowUp || key.char == 'k';
      final isArrowDownOrJKey =
          key.controlChar == ControlCharacter.arrowDown || key.char == 'j';
      final isReturnOrEnterOrSpaceKey =
          key.controlChar == ControlCharacter.ctrlJ ||
              key.controlChar == ControlCharacter.ctrlM ||
              key.char == ' ';

      if (isArrowUpOrKKey) {
        index = (index - 1) % (choices.length);
      } else if (isArrowDownOrJKey) {
        index = (index + 1) % (choices.length);
      } else if (isReturnOrEnterOrSpaceKey) {
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
          ..writeln(
            styleDim.wrap(lightCyan.wrap(resolvedDisplay(choices[index]))),
          );

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
    final resolvedDisplay = display ?? (value) => '$value';
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
            ..write(' $checkBox  ${lightCyan.wrap(resolvedDisplay(choice))}');
        } else {
          _stdout
            ..write(' ')
            ..write(' $checkBox  ${resolvedDisplay(choice)}');
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

    List<T>? results;
    while (results == null) {
      final key = _readKey();
      final keyIsUpOrKKey =
          key.controlChar == ControlCharacter.arrowUp || key.char == 'k';
      final keyIsDownOrJKey =
          key.controlChar == ControlCharacter.arrowDown || key.char == 'j';
      final keyIsSpaceKey = key.char == ' ';
      final keyIsEnterOrReturnKey = key.controlChar == ControlCharacter.ctrlJ ||
          key.controlChar == ControlCharacter.ctrlM;

      if (keyIsUpOrKKey) {
        index = (index - 1) % (choices.length);
      } else if (keyIsDownOrJKey) {
        index = (index + 1) % (choices.length);
      } else if (keyIsSpaceKey) {
        selections.contains(index)
            ? selections.remove(index)
            : selections.add(index);
      } else if (keyIsEnterOrReturnKey) {
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
          ..writeln(
            styleDim.wrap(
              lightCyan.wrap('${results.map(resolvedDisplay).toList()}'),
            ),
          );

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
