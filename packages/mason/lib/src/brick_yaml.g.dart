// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brick_yaml.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrickYaml _$BrickYamlFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const ['name', 'description', 'version', 'vars', 'path'],
  );
  return BrickYaml(
    name: json['name'] as String,
    description: json['description'] as String,
    version: json['version'] as String,
    vars: json['vars'] == null
        ? const <String, BrickVariable>{}
        : const VarsConverter().fromJson(json['vars']),
    path: json['path'] as String?,
  );
}

Map<String, dynamic> _$BrickYamlToJson(BrickYaml instance) {
  final val = <String, dynamic>{
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
  writeNotNull('path', instance.path);
  return val;
}

BrickVariable _$BrickVariableFromJson(Map json) => $checkedCreate(
      'BrickVariable',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['type', 'description', 'default'],
        );
        final val = BrickVariable(
          type: $checkedConvert(
              'type', (v) => $enumDecode(_$BrickVariableTypeEnumMap, v)),
          description: $checkedConvert('description', (v) => v as String?),
          defaultValue: $checkedConvert('default', (v) => v),
        );
        return val;
      },
      fieldKeyMap: const {'defaultValue': 'default'},
    );

Map<String, dynamic> _$BrickVariableToJson(BrickVariable instance) {
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
  return val;
}

const _$BrickVariableTypeEnumMap = {
  BrickVariableType.number: 'number',
  BrickVariableType.string: 'string',
  BrickVariableType.boolean: 'boolean',
};
