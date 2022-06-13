part of '{{name}}_bloc.dart';

@freezed
class {{name.pascalCase()}}Event with _${{name.pascalCase()}}Event {
  const factory {{name.pascalCase()}}Event.started() = _Started;
}
