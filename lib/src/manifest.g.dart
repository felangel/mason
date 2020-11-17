// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Manifest _$ManifestFromJson(Map json) {
  return $checkedNew('Manifest', json, () {
    $checkKeys(json,
        allowedKeys: const ['name', 'description', 'files', 'args']);
    final val = Manifest(
      $checkedConvert(json, 'name', (v) => v as String),
      $checkedConvert(json, 'description', (v) => v as String),
      $checkedConvert(
          json,
          'files',
          (v) => (v as List)
              ?.map((e) => e == null ? null : TemplateFile.fromJson(e as Map))
              ?.toList()),
      $checkedConvert(
          json, 'args', (v) => (v as List)?.map((e) => e as String)?.toList()),
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
  writeNotNull('files', instance.files?.map((e) => e?.toJson())?.toList());
  writeNotNull('args', instance.args);
  return val;
}

TemplateFile _$TemplateFileFromJson(Map json) {
  return $checkedNew('TemplateFile', json, () {
    $checkKeys(json, allowedKeys: const ['from', 'to']);
    final val = TemplateFile(
      $checkedConvert(json, 'from', (v) => v as String),
      $checkedConvert(json, 'to', (v) => v as String),
    );
    return val;
  });
}

Map<String, dynamic> _$TemplateFileToJson(TemplateFile instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('from', instance.from);
  writeNotNull('to', instance.to);
  return val;
}
