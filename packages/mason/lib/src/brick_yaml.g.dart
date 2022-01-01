// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brick_yaml.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrickYaml _$BrickYamlFromJson(Map json) => $checkedCreate(
      'BrickYaml',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['name', 'description', 'version', 'vars', 'path'],
        );
        final val = BrickYaml(
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          version: $checkedConvert('version', (v) => v as String),
          vars: $checkedConvert(
              'vars',
              (v) =>
                  (v as List<dynamic>?)?.map((e) => e as String).toList() ??
                  const <String>[]),
          path: $checkedConvert('path', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$BrickYamlToJson(BrickYaml instance) {
  final val = <String, dynamic>{
    'name': instance.name,
    'description': instance.description,
    'version': instance.version,
    'vars': instance.vars,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('path', instance.path);
  return val;
}
