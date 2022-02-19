import 'package:path/path.dart' as p;

/// Canonicalizes [path].
///
/// This function implements the behaviour of `canonicalize` from
/// `package:path`.
/// However, it does not change the ASCII case of the path.
/// See https://github.com/dart-lang/path/issues/102.
String canonicalize(String path) {
  return p.normalize(p.absolute(path)).replaceAll(r'\', '/');
}
