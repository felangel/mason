/// [TemplateException] is used to obtain the line and column numbers
/// of the token which caused parse or render to fail.
class TemplateException {
  TemplateException(this.message, this.templateName, this.source, this.offset);

  /// A message describing the problem parsing or rendering the template.
  final String message;

  /// The name used to identify the template, as passed to the Template
  /// constructor.
  final String? templateName;

  /// The character offset within the template source.
  final int? offset;

  /// The template source.
  final String? source;

  bool _isUpdated = false;
  late int _line;
  late int _column;
  late String _context;

  /// The 1-based line number of the token where formatting error was found.
  int get line {
    _update();
    return _line;
  }

  /// The 1-based column number of the token where formatting error was found.
  int get column {
    _update();
    return _column;
  }

  /// A short source substring of the source at the point the problem occurred
  /// with parsing or rendering.
  String get context {
    _update();
    return _context;
  }

  String toString() {
    var list = [];
    if (templateName != null) list.add(templateName);
    list.add(line);
    list.add(column);
    var location = list.isEmpty ? '' : ' (${list.join(':')})';
    return '$message$location\n$context';
  }

  // This source code is a modified version of FormatException.toString().
  void _update() {
    if (_isUpdated) return;
    _isUpdated = true;

    if (source == null ||
        offset == null ||
        (offset! < 0 || offset! > source!.length)) return;

    // Find line and character column.
    var lineNum = 1;
    var lineStart = 0;
    var lastWasCR = false;
    for (var i = 0; i < offset!; i++) {
      var char = source!.codeUnitAt(i);
      if (char == 0x0a) {
        if (lineStart != i || !lastWasCR) {
          lineNum += 1;
        }
        lineStart = i + 1;
        lastWasCR = false;
      } else if (char == 0x0d) {
        lineNum++;
        lineStart = i + 1;
        lastWasCR = true;
      }
    }

    _line = lineNum;
    _column = offset! - lineStart + 1;

    // Find context.
    var lineEnd = source!.length;
    for (var i = offset!; i < source!.length; i++) {
      var char = source!.codeUnitAt(i);
      if (char == 0x0a || char == 0x0d) {
        lineEnd = i;
        break;
      }
    }
    var length = lineEnd - lineStart;
    var start = lineStart;
    var end = lineEnd;
    var prefix = '';
    var postfix = '';
    if (length > 78) {
      // Can't show entire line. Try to anchor at the nearest end, if
      // one is within reach.
      var index = offset! - lineStart;
      if (index < 75) {
        end = start + 75;
        postfix = '...';
      } else if (end - offset! < 75) {
        start = end - 75;
        prefix = '...';
      } else {
        // Neither end is near, just pick an area around the offset.
        start = offset! - 36;
        end = offset! + 36;
        prefix = postfix = '...';
      }
    }
    var slice = source!.substring(start, end);
    var markOffset = offset! - start + prefix.length;

    _context = "$prefix$slice$postfix\n${" " * markOffset}^\n";
  }
}
