// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'brick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Brick _$BrickFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Brick',
      json,
      ($checkedConvert) {
        final val = Brick(
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          version: $checkedConvert('version', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at'},
    );
