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
            'environment',
            'repository',
            'readme',
            'changelog',
            'license',
            'vars'
          ],
        );
        final val = MasonBundle(
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          version: $checkedConvert('version', (v) => v as String),
          environment: $checkedConvert(
              'environment',
              (v) => v == null
                  ? const BrickEnvironment()
                  : BrickEnvironment.fromJson(v as Map)),
          vars: $checkedConvert(
              'vars',
              (v) => v == null
                  ? const <String, BrickVariableProperties>{}
                  : const VarsConverter().fromJson(v)),
          files: $checkedConvert(
              'files',
              (v) =>
                  (v as List<dynamic>?)
                      ?.map((e) => MasonBundledFile.fromJson(
                          Map<String, dynamic>.from(e as Map)))
                      .toList() ??
                  const []),
          hooks: $checkedConvert(
              'hooks',
              (v) =>
                  (v as List<dynamic>?)
                      ?.map((e) => MasonBundledFile.fromJson(
                          Map<String, dynamic>.from(e as Map)))
                      .toList() ??
                  const []),
          repository: $checkedConvert('repository', (v) => v as String?),
          readme: $checkedConvert(
              'readme',
              (v) => v == null
                  ? null
                  : MasonBundledFile.fromJson(
                      Map<String, dynamic>.from(v as Map))),
          changelog: $checkedConvert(
              'changelog',
              (v) => v == null
                  ? null
                  : MasonBundledFile.fromJson(
                      Map<String, dynamic>.from(v as Map))),
          license: $checkedConvert(
              'license',
              (v) => v == null
                  ? null
                  : MasonBundledFile.fromJson(
                      Map<String, dynamic>.from(v as Map))),
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
    'environment': instance.environment.toJson(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('repository', instance.repository);
  writeNotNull('readme', instance.readme?.toJson());
  writeNotNull('changelog', instance.changelog?.toJson());
  writeNotNull('license', instance.license?.toJson());
  writeNotNull('vars', const VarsConverter().toJson(instance.vars));
  return val;
}
