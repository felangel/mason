// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brick_yaml.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrickYaml _$BrickYamlFromJson(Map json) {
  return $checkedNew('BrickYaml', json, () {
    $checkKeys(json, allowedKeys: const ['name', 'description', 'vars']);
    final val = BrickYaml(
      $checkedConvert(json, 'name', (v) => v as String),
      $checkedConvert(json, 'description', (v) => v as String),
      $checkedConvert(
          json, 'vars', (v) => (v as List)?.map((e) => e as String)?.toList()),
    );
    return val;
  });
}

Map<String, dynamic> _$BrickYamlToJson(BrickYaml instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('description', instance.description);
  writeNotNull('vars', instance.vars);
  return val;
}
