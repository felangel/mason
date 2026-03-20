// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, strict_raw_type

part of 'mason_lock_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MasonexLockJson _$MasonexLockJsonFromJson(Map json) =>
    $checkedCreate('MasonexLockJson', json, ($checkedConvert) {
      $checkKeys(json, allowedKeys: const ['bricks']);
      final val = MasonexLockJson(
        bricks: $checkedConvert(
          'bricks',
          (v) => (v as Map?)?.map(
            (k, e) => MapEntry(k as String, BrickLocation.fromJson(e)),
          ),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MasonexLockJsonToJson(MasonexLockJson instance) =>
    <String, dynamic>{
      'bricks': instance.bricks.map((k, e) => MapEntry(k, e.toJson())),
    };
