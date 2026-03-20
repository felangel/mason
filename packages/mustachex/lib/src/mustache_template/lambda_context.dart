import 'node.dart';
import 'parser.dart' as parser;
import 'renderer.dart';
import 'template_exception.dart';

typedef LambdaFunction = Object Function(LambdaContext context);

/// Passed as an argument to a mustache lambda function. The methods on
/// this object may only be called before the lambda function returns. If a
/// method is called after it has returned an exception will be thrown.
class LambdaContext {
  final Node _node;
  final Renderer _renderer;
  bool _closed = false;

  LambdaContext(this._node, this._renderer);

  void close() {
    _closed = true;
  }

  void _checkClosed() {
    if (_closed) throw _error('LambdaContext accessed outside of callback.');
  }

  TemplateException _error(String msg) {
    return TemplateException(
        msg, _renderer.templateName, _renderer.source, _node.start);
  }

  /// Render the current section tag in the current context and return the
  /// result as a string. If provided, value will be added to the top of the
  /// context's stack.
  String renderString({Object? value}) {
    _checkClosed();
    if (_node is! SectionNode) {
      _error(
          'LambdaContext.renderString() can only be called on section tags.');
    }
    var sink = StringBuffer();
    _renderSubtree(sink, value);
    return sink.toString();
  }

  void _renderSubtree(StringSink sink, Object? value) {
    var renderer = Renderer.subtree(_renderer, sink);
    var section = _node as SectionNode;
    if (value != null) renderer.push(value);
    renderer.render(section.children);
  }

  /// Render and directly output the current section tag. If provided, value
  /// will be added to the top of the context's stack.
  void render({Object? value}) {
    _checkClosed();
    if (_node is! SectionNode) {
      _error('LambdaContext.render() can only be called on section tags.');
    }
    _renderSubtree(_renderer.sink, value);
  }

  /// Output a string. The output will not be html escaped, and will be written
  /// before the output returned from the lambda.
  void write(Object object) {
    _checkClosed();
    _renderer.write(object);
  }

  /// Get the unevaluated template source for the current section tag.
  String get source {
    _checkClosed();

    if (_node is! SectionNode) return '';

    var node = _node as SectionNode;
    var nodes = node.children;
    if (nodes.isEmpty) return '';

    if (nodes.length == 1 && nodes.first is TextNode) {
      return (nodes.single as TextNode).text;
    }

    return _renderer.source.substring(node.contentStart, node.contentEnd);
  }

  /// Evaluate the string as a mustache template using the current context. If
  /// provided, value will be added to the top of the context's stack.
  String renderSource(String source, {Object? value}) {
    _checkClosed();
    var sink = StringBuffer();

    // Lambdas used for sections should parse with the current delimiters.
    var delimiters = '{{ }}';
    if (_node is SectionNode) {
      var node = _node as SectionNode;
      delimiters = node.delimiters;
    }

    var nodes = parser.parse(
        source, _renderer.lenient, _renderer.templateName, delimiters);

    var renderer =
        Renderer.lambda(_renderer, source, _renderer.indent, sink, delimiters);

    if (value != null) renderer.push(value);
    renderer.render(nodes);

    return sink.toString();
  }

  /// Lookup the value of a variable in the current context.
  Object? lookup(String variableName) {
    _checkClosed();
    return _renderer.resolveValue(variableName);
  }
}
