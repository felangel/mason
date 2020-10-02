final _substitueRegExp = RegExp(r'__([a-zA-Z]+)__');
final _nonValidSubstitueRegExp = RegExp('[^a-zA-Z]');

/// Given a `String` [str] with mustache templates, and a [Map] of String key /
/// value pairs, substitute all instances of `__key__` for `value`. I.e.,
///
/// ```
/// Foo __projectName__ baz.
/// ```
///
/// and
///
/// ```
/// {'projectName': 'bar'}
/// ```
///
/// becomes:
///
/// ```
/// Foo bar baz.
/// ```
///
/// A key value can only be an ASCII string made up of letters: A-Z, a-z.
/// No whitespace, numbers, or other characters are allowed.
String substituteVars(String str, Map<String, String> vars) {
  var nonValidKeys =
      vars.keys.where((k) => k.contains(_nonValidSubstitueRegExp)).toList();
  if (nonValidKeys.isNotEmpty) {
    throw ArgumentError('vars.keys can only contain letters.');
  }

  return str.replaceAllMapped(_substitueRegExp, (match) {
    var item = vars[match[1]];

    if (item == null) {
      return match[0];
    } else {
      return item;
    }
  });
}
