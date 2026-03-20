import 'dart:async';
import 'dart:io' as dart_io;
import 'package:mason_logger/src/ffi/terminal.dart';
import 'package:mason_logger/src/io.dart' as io;

const _asyncRunZoned = runZoned;

/// This class facilitates overriding terminal utilities.
/// It should be extended by another class in client code with overrides
/// that construct a custom implementation.
abstract class TerminalOverrides {
  static final _token = Object();

  /// Returns the current [TerminalOverrides] instance.
  ///
  /// This will return `null` if the current [Zone] does not contain
  /// any [TerminalOverrides].
  ///
  /// See also:
  /// * [TerminalOverrides.runZoned] to provide [TerminalOverrides]
  /// in a fresh [Zone].
  ///
  static TerminalOverrides? get current {
    return Zone.current[_token] as TerminalOverrides?;
  }

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  static R runZoned<R>(
    R Function() body, {
    io.KeyStroke Function()? readKey,
    Terminal Function()? createTerminal,
    Never Function(int code)? exit,
  }) {
    final overrides = _TerminalOverridesScope(readKey, createTerminal, exit);
    return _asyncRunZoned(body, zoneValues: {_token: overrides});
  }

  /// The function used to read key strokes from stdin.
  io.KeyStroke Function() get readKey => io.readKey;

  /// The function used to create a [Terminal] instance.
  Terminal Function() get createTerminal => Terminal.new;

  /// Exit the process with the provided [code].
  Never exit(int code) => dart_io.exit(code); // coverage:ignore-line
}

class _TerminalOverridesScope extends TerminalOverrides {
  _TerminalOverridesScope(this._readKey, this._createTerminal, this._exit);

  final TerminalOverrides? _previous = TerminalOverrides.current;
  final io.KeyStroke Function()? _readKey;
  final Terminal Function()? _createTerminal;
  final Never Function(int code)? _exit;

  @override
  io.KeyStroke Function() get readKey {
    return _readKey ?? _previous?.readKey ?? super.readKey;
  }

  @override
  Terminal Function() get createTerminal {
    return _createTerminal ?? _previous?.createTerminal ?? super.createTerminal;
  }

  @override
  Never exit(int code) => (_exit ?? _previous?.exit ?? super.exit)(code);
}
