/// Helper function for "wrapping" an message optional message with link.
String linkWrap(String? message, Uri uri) {
  const lead = '\x1B]8;;';
  const trail = '\x1B\\';

  final encoded = '$lead$uri$trail${message ?? uri}$lead$trail';
  return encoded;
}
