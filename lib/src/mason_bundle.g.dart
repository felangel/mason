// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mason_bundle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MasonBundledFile _$MasonBundledFileFromJson(Map json) {
  return $checkedNew('MasonBundledFile', json, () {
    $checkKeys(json, allowedKeys: const ['path', 'data', 'type']);
    final val = MasonBundledFile(
      $checkedConvert(json, 'path', (v) => v as String),
      $checkedConvert(json, 'data', (v) => v as String),
      $checkedConvert(json, 'type', (v) => v as String),
    );
    return val;
  });
}

Map<String, dynamic> _$MasonBundledFileToJson(MasonBundledFile instance) =>
    <String, dynamic>{
      'path': instance.path,
      'data': instance.data,
      'type': instance.type,
    };

MasonBundle _$MasonBundleFromJson(Map json) {
  return $checkedNew('MasonBundle', json, () {
    $checkKeys(json,
        allowedKeys: const ['files', 'hooks', 'name', 'description', 'vars']);
    final val = MasonBundle(
      $checkedConvert(json, 'name', (v) => v as String),
      $checkedConvert(json, 'description', (v) => v as String),
      $checkedConvert(json, 'vars',
          (v) => (v as List<dynamic>).map((e) => e as String).toList()),
      $checkedConvert(
          json,
          'files',
          (v) => (v as List<dynamic>)
              .map((e) => MasonBundledFile.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList()),
      $checkedConvert(
          json,
          'hooks',
          (v) => (v as List<dynamic>)
              .map((e) => MasonBundledFile.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList()),
    );
    return val;
  });
}

Map<String, dynamic> _$MasonBundleToJson(MasonBundle instance) =>
    <String, dynamic>{
      'files': instance.files.map((e) => e.toJson()).toList(),
      'hooks': instance.hooks.map((e) => e.toJson()).toList(),
      'name': instance.name,
      'description': instance.description,
      'vars': instance.vars,
    };
