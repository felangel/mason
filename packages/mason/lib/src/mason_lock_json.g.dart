// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mason_lock_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MasonLockJson _$MasonLockJsonFromJson(Map json) => $checkedCreate(
      'MasonLockJson',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['bricks'],
        );
        final val = MasonLockJson(
          bricks: $checkedConvert(
              'bricks',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, BrickLocation.fromJson(e)),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$MasonLockJsonToJson(MasonLockJson instance) =>
    <String, dynamic>{
      'bricks': instance.bricks.map((k, e) => MapEntry(k, e.toJson())),
    };
