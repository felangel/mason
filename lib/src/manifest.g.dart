// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Manifest _$ManifestFromJson(Map json) {
  return $checkedNew('Manifest', json, () {
    $checkKeys(json,
        allowedKeys: const ['name', 'description', 'brick', 'vars']);
    final val = Manifest(
      $checkedConvert(json, 'name', (v) => v as String),
      $checkedConvert(json, 'description', (v) => v as String),
      $checkedConvert(
          json, 'vars', (v) => (v as List)?.map((e) => e as String)?.toList()),
      brick: $checkedConvert(json, 'brick', (v) => v as String),
    );
    return val;
  });
}

Map<String, dynamic> _$ManifestToJson(Manifest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('description', instance.description);
  writeNotNull('brick', instance.brick);
  writeNotNull('vars', instance.vars);
  return val;
}
