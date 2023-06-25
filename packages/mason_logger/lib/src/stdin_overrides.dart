import 'dart:async';
import 'package:mason_logger/src/io.dart' as io;

const _asyncRunZoned = runZoned;

/// This class facilitates overriding stdin utilities for reading key strokes.
/// It should be extended by another class in client code with overrides
/// that construct a custom implementation.
abstract class StdinOverrides {
  static final _token = Object();

  /// Returns the current [StdinOverrides] instance.
  ///
  /// This will return `null` if the current [Zone] does not contain
  /// any [StdinOverrides].
  ///
  /// See also:
  /// * [StdinOverrides.runZoned] to provide [StdinOverrides]
  /// in a fresh [Zone].
  ///
  static StdinOverrides? get current {
    return Zone.current[_token] as StdinOverrides?;
  }

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  static R runZoned<R>(
    R Function() body, {
    io.KeyStroke Function()? readKey,
  }) {
    final overrides = _StdinOverridesScope(readKey);
    return _asyncRunZoned(body, zoneValues: {_token: overrides});
  }

  /// The function used to read key strokes from stdin.
  io.KeyStroke Function() get readKey => io.readKey;
}

class _StdinOverridesScope extends StdinOverrides {
  _StdinOverridesScope(this._readKey);

  final StdinOverrides? _previous = StdinOverrides.current;
  final io.KeyStroke Function()? _readKey;

  @override
  io.KeyStroke Function() get readKey {
    return _readKey ?? _previous?.readKey ?? super.readKey;
  }
}
