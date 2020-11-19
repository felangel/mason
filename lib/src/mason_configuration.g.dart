// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mason_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MasonConfiguration _$MasonConfigurationFromJson(Map json) {
  return $checkedNew('MasonConfiguration', json, () {
    $checkKeys(json, allowedKeys: const ['templates']);
    final val = MasonConfiguration(
      $checkedConvert(
          json,
          'templates',
          (v) => (v as Map)?.map(
                (k, e) => MapEntry(k as String,
                    e == null ? null : MasonTemplate.fromJson(e as Map)),
              )),
    );
    return val;
  });
}

Map<String, dynamic> _$MasonConfigurationToJson(MasonConfiguration instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'templates', instance.templates?.map((k, e) => MapEntry(k, e?.toJson())));
  return val;
}

MasonTemplate _$MasonTemplateFromJson(Map json) {
  return $checkedNew('MasonTemplate', json, () {
    $checkKeys(json, allowedKeys: const ['path']);
    final val = MasonTemplate(
      $checkedConvert(json, 'path', (v) => v as String),
    );
    return val;
  });
}

Map<String, dynamic> _$MasonTemplateToJson(MasonTemplate instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('path', instance.path);
  return val;
}
