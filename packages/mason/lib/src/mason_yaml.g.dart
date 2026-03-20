// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, strict_raw_type

part of 'mason_yaml.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MasonYaml _$MasonYamlFromJson(Map json) => $checkedCreate(
      'MasonYaml',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['bricks'],
        );
        final val = MasonYaml(
          $checkedConvert(
              'bricks',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, BrickLocation.fromJson(e)),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$MasonYamlToJson(MasonYaml instance) => <String, dynamic>{
      'bricks': instance.bricks.map((k, e) => MapEntry(k, e.toJson())),
    };

BrickLocation _$BrickLocationFromJson(Map json) => $checkedCreate(
      'BrickLocation',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['path', 'git', 'version'],
        );
        final val = BrickLocation(
          path: $checkedConvert('path', (v) => v as String?),
          git: $checkedConvert(
              'git', (v) => v == null ? null : GitPath.fromJson(v as Map)),
          version: $checkedConvert('version', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$BrickLocationToJson(BrickLocation instance) =>
    <String, dynamic>{
      if (instance.path case final value?) 'path': value,
      if (instance.git?.toJson() case final value?) 'git': value,
      if (instance.version case final value?) 'version': value,
    };

GitPath _$GitPathFromJson(Map json) => $checkedCreate(
      'GitPath',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['url', 'path', 'ref'],
        );
        final val = GitPath(
          $checkedConvert('url', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String?),
          ref: $checkedConvert('ref', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$GitPathToJson(GitPath instance) => <String, dynamic>{
      'url': instance.url,
      'path': instance.path,
      if (instance.ref case final value?) 'ref': value,
    };
