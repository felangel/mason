import 'dart:async';
import 'dart:io' as io;

const _asyncRunZoned = runZoned;

/// This class facilitates overriding [io.stdioType].
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
    io.StdioType Function(dynamic object) Function()? stdioType,
  }) {
    final overrides = _StdioOverridesScope(stdioType);
    return _asyncRunZoned(
      body,
      zoneValues: {_token: overrides},
    );
  }

  /// The [io.stdioType] that will be used for errors within the current [Zone].
  io.StdioType Function(dynamic object) get stdioType => io.stdioType;
}

class _StdioOverridesScope extends StdioOverrides {
  _StdioOverridesScope(this._stdioType);

  final StdioOverrides? _previous = StdioOverrides.current;
  final io.StdioType Function(dynamic object) Function()? _stdioType;

  @override
  io.StdioType Function(dynamic object) get stdioType {
    return _stdioType?.call() ?? _previous?.stdioType ?? super.stdioType;
  }
}
