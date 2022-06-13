import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '{{name}}_event.dart';
part '{{name}}_state.dart';
part '{{name}}_bloc.freezed.dart';

class {{name.pascalCase()}}Bloc extends Bloc<{{name.pascalCase()}}Event, {{name.pascalCase()}}State> {
  {{name.pascalCase()}}Bloc() : super(_Initial()) {
    on<{{name.pascalCase()}}Event>((event, emit) {
      // TODO: implement event handler
    });
  }
}
