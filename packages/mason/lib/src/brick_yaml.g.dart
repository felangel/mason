// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brick_yaml.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrickYaml _$BrickYamlFromJson(Map json) {
  return $checkedNew('BrickYaml', json, () {
    $checkKeys(json,
        allowedKeys: const ['name', 'description', 'vars', 'path']);
    final val = BrickYaml(
      $checkedConvert(json, 'name', (v) => v as String),
      $checkedConvert(json, 'description', (v) => v as String),
      vars: $checkedConvert(json, 'vars',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()) ??
          [],
      path: $checkedConvert(json, 'path', (v) => v as String?),
    );
    return val;
  });
}

Map<String, dynamic> _$BrickYamlToJson(BrickYaml instance) {
  final val = <String, dynamic>{
    'name': instance.name,
    'description': instance.description,
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
