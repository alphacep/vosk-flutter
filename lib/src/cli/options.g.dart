// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'options.dart';

// **************************************************************************
// CliGenerator
// **************************************************************************

T _$enumValueHelper<T>(Map<T, String> enumValues, String source) =>
    enumValues.entries
        .singleWhere(
          (e) => e.value == source,
          orElse: () => throw ArgumentError(
            '`$source` is not one of the supported values: '
            '${enumValues.values.join(', ')}',
          ),
        )
        .key;

T? _$nullableEnumValueHelperNullable<T>(
  Map<T, String> enumValues,
  String? source,
) =>
    source == null ? null : _$enumValueHelper(enumValues, source);

Options _$parseOptionsResult(ArgResults result) => Options()
  ..targetOsType = _$nullableEnumValueHelperNullable(
    _$TargetOsTypeEnumMapBuildCli,
    result['target-os-type'] as String?,
  );

const _$TargetOsTypeEnumMapBuildCli = <TargetOsType, String>{
  TargetOsType.linux: 'linux',
  TargetOsType.windows: 'windows',
  TargetOsType.android: 'android'
};

ArgParser _$populateOptionsParser(ArgParser parser) => parser
  ..addOption(
    'target-os-type',
    abbr: 't',
    help: 'The target OS to install binaries for.',
    allowed: ['linux', 'windows', 'android'],
  );

final _$parserForOptions = _$populateOptionsParser(ArgParser());

Options parseOptions(List<String> args) {
  final result = _$parserForOptions.parse(args);
  return _$parseOptionsResult(result);
}
