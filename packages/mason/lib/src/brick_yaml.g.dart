// GENERATED CODE - DO NOT MODIFY BY HAND

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
            'vars',
            'path'
          ],
        );
        final val = BrickYaml(
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
          repository: $checkedConvert('repository', (v) => v as String?),
          path: $checkedConvert('path', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$BrickYamlToJson(BrickYaml instance) {
  final val = <String, dynamic>{
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
  writeNotNull('vars', const VarsConverter().toJson(instance.vars));
  writeNotNull('path', instance.path);
  return val;
}

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
            'values'
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
        );
        return val;
      },
      fieldKeyMap: const {
        'defaultValue': 'default',
        'defaultValues': 'defaults'
      },
    );

Map<String, dynamic> _$BrickVariablePropertiesToJson(
    BrickVariableProperties instance) {
  final val = <String, dynamic>{
    'type': _$BrickVariableTypeEnumMap[instance.type],
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('description', instance.description);
  writeNotNull('default', instance.defaultValue);
  writeNotNull('defaults', instance.defaultValues);
  writeNotNull('prompt', instance.prompt);
  writeNotNull('values', instance.values);
  return val;
}

const _$BrickVariableTypeEnumMap = {
  BrickVariableType.array: 'array',
  BrickVariableType.number: 'number',
  BrickVariableType.string: 'string',
  BrickVariableType.boolean: 'boolean',
  BrickVariableType.enumeration: 'enum',
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
