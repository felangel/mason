// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, strict_raw_type

part of 'brick_yaml.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrickYaml _$BrickYamlFromJson(Map json) => $checkedCreate(
      'BrickYaml',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'name',
            'description',
            'version',
            'environment',
            'repository',
            'publish_to',
            'vars',
            'path'
          ],
        );
        final val = BrickYaml(
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          version: $checkedConvert('version', (v) => v as String),
          publishTo: $checkedConvert('publish_to', (v) => v as String?),
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
          repository: $checkedConvert('repository', (v) => v as String?),
          path: $checkedConvert('path', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'publishTo': 'publish_to'},
    );

Map<String, dynamic> _$BrickYamlToJson(BrickYaml instance) => <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
      'environment': instance.environment.toJson(),
      if (instance.repository case final value?) 'repository': value,
      if (instance.publishTo case final value?) 'publish_to': value,
      if (const VarsConverter().toJson(instance.vars) case final value?)
        'vars': value,
      if (instance.path case final value?) 'path': value,
    };

BrickVariableProperties _$BrickVariablePropertiesFromJson(Map json) =>
    $checkedCreate(
      'BrickVariableProperties',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'type',
            'description',
            'default',
            'defaults',
            'prompt',
            'values',
            'separator'
          ],
        );
        final val = BrickVariableProperties(
          type: $checkedConvert(
              'type', (v) => $enumDecode(_$BrickVariableTypeEnumMap, v)),
          description: $checkedConvert('description', (v) => v as String?),
          defaultValue: $checkedConvert('default', (v) => v),
          defaultValues: $checkedConvert('defaults', (v) => v),
          prompt: $checkedConvert('prompt', (v) => v as String?),
          values: $checkedConvert('values',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          separator: $checkedConvert('separator', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'defaultValue': 'default',
        'defaultValues': 'defaults'
      },
    );

Map<String, dynamic> _$BrickVariablePropertiesToJson(
        BrickVariableProperties instance) =>
    <String, dynamic>{
      'type': _$BrickVariableTypeEnumMap[instance.type]!,
      if (instance.description case final value?) 'description': value,
      if (instance.defaultValue case final value?) 'default': value,
      if (instance.defaultValues case final value?) 'defaults': value,
      if (instance.prompt case final value?) 'prompt': value,
      if (instance.values case final value?) 'values': value,
      if (instance.separator case final value?) 'separator': value,
    };

const _$BrickVariableTypeEnumMap = {
  BrickVariableType.array: 'array',
  BrickVariableType.number: 'number',
  BrickVariableType.string: 'string',
  BrickVariableType.boolean: 'boolean',
  BrickVariableType.enumeration: 'enum',
  BrickVariableType.list: 'list',
};

BrickEnvironment _$BrickEnvironmentFromJson(Map json) => $checkedCreate(
      'BrickEnvironment',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['mason'],
        );
        final val = BrickEnvironment(
          mason: $checkedConvert('mason', (v) => v as String? ?? 'any'),
        );
        return val;
      },
    );

Map<String, dynamic> _$BrickEnvironmentToJson(BrickEnvironment instance) =>
    <String, dynamic>{
      'mason': instance.mason,
    };
