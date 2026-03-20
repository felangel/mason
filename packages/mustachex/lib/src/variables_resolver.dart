import 'package:mustachex/src/variable_recase_decomposer.dart';
import 'package:recase/recase.dart';

/// Will hold a bunch of variables and provide tools for obtaining them
class VariablesResolver {
  final Map<String?, dynamic> _mem = {};
  // Function missingResolver;

  final Map<String, String> recasingsShorthands = const {
    'cc': 'camelCase',
    'sc': 'snakeCase',
    'pc': 'pascalCase',
  };

  VariablesResolver([Map? initialVars]) {
    // VariablesResolver([Map initialVars, Function demandingMissingresolver]) {
    if (initialVars != null) addAll(initialVars);
    // missingResolver = demandingMissingresolver;
  }

  dynamic operator [](key) => get(key);

  /// Returns the requested variable following the maps parents structure
  /// if so indicated through list of it names, or `null` if it's not defined.
  /// It also converts to a recased string if so demanded. e.g.:
  /// varName_cc -> varName.camelCase
  /// varName_pascalCase -> varName.pascalCase
  dynamic get(request) {
    if (request is String) {
      //formalo bien en List
      request = [request];
    } else if (request is! List) {
      //tiene q ser list si o si
      throw ArgumentError.value(
          request, 'request', 'Must be of type List/String');
    }
    //averiguemos lo que tenemos que devolver
    dynamic ret = _mem;
    for (var i = 0; i < (request as List).length; i++) {
      var testVar;
      try {
        testVar = ret[request[i]];
      } catch (_) {
        testVar = null;
      }
      if (testVar == null) {
        //si lo que pedimos (ponele q 'nombre_pc') no lo encuentra,
        //probemos con 'nombre' asi nomás a ver si está
        var decomposition = VariableRecaseDecomposer(request[i].toString());
        try {
          testVar = ret[decomposition.varName];
        } catch (_) {
          testVar = null;
        }
        if (testVar != null) {
          //está: entonces reconvirtamos y ya fue
          var recase = decomposition.recasing;
          if (recasingsShorthands.keys.contains(recase)) {
            //está en pocas letras, pero necesitamos el nombre completo
            recase = recasingsShorthands[recase!];
          }
          try {
            if (recase != null && recase.endsWith('Case')) {
              //es un recasing, reconvirtamos
              ret = ret[decomposition.varName][recase];
            } else {
              //no fue recasing, pero está, sigamos con lo q sea q esté
              ret = ret[decomposition.varName];
            }
          } on NoSuchMethodError catch (_) {
            //tiró error en el recasing
            throw StateError("Couldn't convert to '$recase' "
                "when resolving variable request '${request.join('.')}'");
          }
        } else {
          //no está: entonces es null y fue, viteh?
          return null;
        }
      } else {
        //si lo encuentra cargalo nomás
        ret = ret[request[i]];
        //Si hay una lista, throwear (cómo se cuáles elementos agarrar?)
        if (ret is List && i < request.length - 1) {
          throw VarFromListRequestException(request, i);
        }
      }
    }
    return ret;
  }

  Map get getAll => Map.unmodifiable(_mem);

  // La idea es que cuando te manden una lista de keys, se agregue en
  // el lugar que corresponde el value. Está hecho para que cuando se
  // pregunta por el valor de una variable que falta dentro de un
  // {{#mapaPadre}}{{valor}}{{/mapaPadre}} se agregue dentro del map o list
  // de mapaPadre
  void operator []=(keys, value) {
    String? memVar = '';
    List? keysList;
    if (keys is List) {
      keysList = List.from(keys);
      memVar = keysList.removeAt(0);
    } else if (keys is! String && keys is! StringVariable) {
      throw MalformedVariablesMap(keys, value);
    } else {
      memVar = keys;
      keysList = [keysList];
    }
    if (_mem[memVar] is Iterable && keysList.length > 1) {
      _mem[memVar] =
          _recursiveAssignment(keysList, _mem[memVar], _process(value));
    } else {
      _mem[memVar] = _process(value);
    }
    // print("Asignado a $memVar: ${_mem[memVar]}");
  }

  //Va iterando en la lista de asignaciones y agrega como corresponde
  dynamic _recursiveAssignment(List keys, from, assignment) {
    if (from is List) {
      throw ArgumentError('from must be a Map, not a List');
    }
    if (keys.isEmpty || from == null) {
      return assignment;
    } else if (keys.length == 1) {
      if (from[keys.first] == null) {
        return assignment;
      } else {
        from[keys.first] = assignment;
        return from;
      }
    } else {
      try {
        from[keys.first] =
            _recursiveAssignment(keys.sublist(1), from[keys.first], assignment);
      } catch (e) {
        print(e);
      }
      return from;
    }
  }

  //Convierte el value en algo usable, bien formateado, etc
  dynamic _process(value) {
    if (value is String) {
      return StringVariable(value);
    } else if (value is StringVariable || value is bool || value is num) {
      return value;
    } else if (value == null) {
      return null;
    } else if (value is List) {
      var ret = [];
      value.forEach((v) {
        ret.add(_process(v));
      });
      return ret;
    } else if (value is Map) {
      var ret = {};
      value.forEach((k, v) {
        ret[k] = _process(v);
      });
      return ret;
      // } else {
      //   // Una complejidad añadida para guardar clases y enums, creo
      //   ClassAnalysis valAnalysis = ClassAnalysis.fromInstance(value);
      //   if (valAnalysis.isEnum) {
      //     return StringVariable(value.toString());
      //   }
      //   Map ret = valAnalysis.toMap();
      //   ret['className'] = valAnalysis.name;
      //   return ret;
    }
  }

  void addAll(Map vars) {
    vars.forEach((key, value) {
      this[key] = value;
    });
  }
}

class VarFromListRequestException implements Exception {
  final List request;
  final int index;
  final List parentCollections;

  VarFromListRequestException(this.request, this.index)
      : parentCollections = request.sublist(0, index + 1);

  @override
  String toString() => "You are requesting '${request.join('.')}' "
      "in variablesResolver but '${request[index]}' is a List and "
      "shouldn't be returned unless the request had been "
      "'${request.sublist(0, index + 1).join('.')}'";
}

class UnconvertibleException implements Exception {
  final value;
  UnconvertibleException(this.value);
}

class MalformedVariablesMap implements Exception {
  String message;
  MalformedVariablesMap(key, value)
      : message =
            'Map<String,(some razonable type)> must be provided, but one of '
                'the tuples is a <${key.runtimeType}, ${value.runtimeType}>';
}

/// A [String] variable with steroids for easy recasing
class StringVariable {
  final String _original;
  late ReCase _reCasedOriginal;

  StringVariable(this._original) {
    _reCasedOriginal = ReCase(_original);
  }

  @override
  String toString() => _original;

  String toJson() => _original;

  //ReCase implementation
  String get camelCase => _reCasedOriginal.camelCase;
  String get constantCase => _reCasedOriginal.constantCase;
  String get dotCase => _reCasedOriginal.dotCase;
  String get headerCase => _reCasedOriginal.headerCase;
  String get paramCase => _reCasedOriginal.paramCase;
  String get pascalCase => _reCasedOriginal.pascalCase;
  String get pathCase => _reCasedOriginal.pathCase;
  String get sentenceCase => _reCasedOriginal.sentenceCase;
  String get snakeCase => _reCasedOriginal.snakeCase;
  String get titleCase => _reCasedOriginal.titleCase;

  /// Used to recase via `VariableResolver["varName"]["xxxCase"]`
  String operator [](key) {
    if (key == 'cc') {
      return camelCase;
    } else if (key == 'camelCase') {
      return camelCase;
    } else if (key == 'constantCase') {
      return constantCase;
    } else if (key == 'dotCase') {
      return dotCase;
    } else if (key == 'headerCase') {
      return headerCase;
    } else if (key == 'paramCase') {
      return paramCase;
    } else if (key == 'pascalCase') {
      return pascalCase;
    } else if (key == 'pc') {
      return pascalCase;
    } else if (key == 'pathCase') {
      return pathCase;
    } else if (key == 'sentenceCase') {
      return sentenceCase;
    } else if (key == 'snakeCase') {
      return snakeCase;
    } else if (key == 'sc') {
      return snakeCase;
    } else if (key == 'titleCase') {
      return titleCase;
    } else {
      throw UnsupportedError("'$key' recasing is not supported");
    }
  }

  @override
  bool operator ==(other) => other.hashCode == _original.hashCode;

  int? compareTo(other) => other.compareTo(_original);

  @override
  int get hashCode => _original.hashCode;
}
