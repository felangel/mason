import 'dart:async';
import 'package:mason_logger/src/key_stroke.dart' as key_stroke;

const _asyncRunZoned = runZoned;

/// This class facilitates overriding stdin utilities for reading key strokes.
/// It should be extended by another class in client code with overrides
/// that construct a custom implementation.
abstract class KeyStrokeOverrides {
  static final _token = Object();

  /// Returns the current [KeyStrokeOverrides] instance.
  ///
  /// This will return `null` if the current [Zone] does not contain
  /// any [KeyStrokeOverrides].
  ///
  /// See also:
  /// * [KeyStrokeOverrides.runZoned] to provide [KeyStrokeOverrides]
  /// in a fresh [Zone].
  ///
  static KeyStrokeOverrides? get current {
    return Zone.current[_token] as KeyStrokeOverrides?;
  }

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  static R runZoned<R>(
    R Function() body, {
    key_stroke.KeyStroke Function()? readKeyStroke,
  }) {
    final overrides = _KeyStrokeOverridesScope(readKeyStroke);
    return _asyncRunZoned(body, zoneValues: {_token: overrides});
  }

  /// The function used to read key strokes from stdin.
  key_stroke.KeyStroke Function() get readKeyStroke => key_stroke.readKeyStroke;
}

class _KeyStrokeOverridesScope extends KeyStrokeOverrides {
  _KeyStrokeOverridesScope(this._readKeyStroke);

  final KeyStrokeOverrides? _previous = KeyStrokeOverrides.current;
  final key_stroke.KeyStroke Function()? _readKeyStroke;

  @override
  key_stroke.KeyStroke Function() get readKeyStroke {
    return _readKeyStroke ?? _previous?.readKeyStroke ?? super.readKeyStroke;
  }
}
