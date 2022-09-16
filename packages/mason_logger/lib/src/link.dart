/// Wraps [uri] with an escape sequence so it's recognized as a hyperlink.
/// An optional message can be used in place of the [uri].
/// If no [message] is provided, the text content will be the full [uri].
///
/// ```dart
/// final plainLink = link(uri: Uri.parse('https://dart.dev'));
/// print(plainLink); // Equivalent to `[https://dart.dev](https://dart.dev)` in markdown
///
/// final richLink = link(uri: Uri.parse('https://dart.dev'), message: 'The Dart Website');
/// print(richLink); // Equivalent to `[The Dart Website](https://dart.dev)` in markdown
/// ```
String link({required Uri uri, String? message}) {
  const leading = '\x1B]8;;';
  const trailing = '\x1B\\';

  return '$leading$uri$trailing${message ?? uri}$leading$trailing';
}
