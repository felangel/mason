// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mason_bundle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MasonBundledFile _$MasonBundledFileFromJson(Map json) => $checkedCreate(
      'MasonBundledFile',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['path', 'data', 'type'],
        );
        final val = MasonBundledFile(
          $checkedConvert('path', (v) => v as String),
          $checkedConvert('data', (v) => v as String),
          $checkedConvert('type', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$MasonBundledFileToJson(MasonBundledFile instance) =>
    <String, dynamic>{
      'path': instance.path,
      'data': instance.data,
      'type': instance.type,
    };

MasonBundle _$MasonBundleFromJson(Map json) => $checkedCreate(
      'MasonBundle',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'files',
            'hooks',
            'name',
            'description',
            'version',
            'vars'
          ],
        );
        final val = MasonBundle(
          $checkedConvert('name', (v) => v as String),
          $checkedConvert('description', (v) => v as String),
          $checkedConvert('version', (v) => v as String),
          $checkedConvert('vars', (v) => const VarsConverter().fromJson(v)),
          $checkedConvert(
              'files',
              (v) => (v as List<dynamic>)
                  .map((e) => MasonBundledFile.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          $checkedConvert(
              'hooks',
              (v) =>
                  (v as List<dynamic>?)
                      ?.map((e) => MasonBundledFile.fromJson(
                          Map<String, dynamic>.from(e as Map)))
                      .toList() ??
                  []),
        );
        return val;
      },
    );

Map<String, dynamic> _$MasonBundleToJson(MasonBundle instance) {
  final val = <String, dynamic>{
    'files': instance.files.map((e) => e.toJson()).toList(),
    'hooks': instance.hooks.map((e) => e.toJson()).toList(),
    'name': instance.name,
    'description': instance.description,
    'version': instance.version,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('vars', const VarsConverter().toJson(instance.vars));
  return val;
}
