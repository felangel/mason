/// A decompositor of recased variable requests.
/// Given a `request`, it's automatically decomposed from the
/// "`varName`(_`recasing`)?" format
class VariableRecaseDecomposer {
  String? _varName;
  String? _recasing;
  final String _request;

  VariableRecaseDecomposer(this._request) {
    if (_request.contains(RegExp(r'(.c|Case)$'))) {
      var casingAnalyzer = RegExp(r'(\w+)_([A-Za-z]{2,})$');
      Match match = casingAnalyzer.firstMatch(_request)!;
      _varName = match.group(1);
      _recasing = match.group(2);
    } else {
      _varName = _request;
    }
  }

  /// The complete requested variable string, like varName_constantCase
  String get request => _request;

  /// The variable part of the request, like varName
  String? get varName => _varName;

  /// The eventual recasing part of the request, like camelCase
  String? get recasing => _recasing;
}
