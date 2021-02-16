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

Map<String, dynamic> _$MasonBundledFileToJson(MasonBundledFile instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('path', instance.path);
  writeNotNull('data', instance.data);
  writeNotNull('type', instance.type);
  return val;
}

MasonBundle _$MasonBundleFromJson(Map json) {
  return $checkedNew('MasonBundle', json, () {
    $checkKeys(json,
        allowedKeys: const ['files', 'name', 'description', 'vars']);
    final val = MasonBundle(
      $checkedConvert(json, 'name', (v) => v as String),
      $checkedConvert(json, 'description', (v) => v as String),
      $checkedConvert(
          json, 'vars', (v) => (v as List)?.map((e) => e as String)?.toList()),
      $checkedConvert(
          json,
          'files',
          (v) => (v as List)
              ?.map((e) => e == null
                  ? null
                  : MasonBundledFile.fromJson((e as Map)?.map(
                      (k, e) => MapEntry(k as String, e),
                    )))
              ?.toList()),
    );
    return val;
  });
}

Map<String, dynamic> _$MasonBundleToJson(MasonBundle instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('files', instance.files?.map((e) => e?.toJson())?.toList());
  writeNotNull('name', instance.name);
  writeNotNull('description', instance.description);
  writeNotNull('vars', instance.vars);
  return val;
}
