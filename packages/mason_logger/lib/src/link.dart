/// Helper function for "encoding" an optional message with link.
String link({
  required Uri uri,
  String? message,
}) {
  const lead = '\x1B]8;;';
  const trail = '\x1B\\';

  final encoded = '$lead$uri$trail${message ?? uri}$lead$trail';
  return encoded;
}
