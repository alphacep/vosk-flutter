import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:vosk_flutter/src/cli/target_os_type.dart';

part 'options.g.dart';

/// Options of the Install command.
@CliOptions()
class Options {
  /// Target OS type, determines binaries to load.
  @CliOption(help: 'The target OS to install binaries for.', abbr: 't')
  TargetOsType? targetOsType;
}

/// See [ArgParser.usage].
String get usage => _$parserForOptions.usage;

/// Populate parser with generated options.
ArgParser populateOptionsParser(ArgParser p) => _$populateOptionsParser(p);

/// Parse options.
Options parseOptionsResult(ArgResults results) => _$parseOptionsResult(results);
