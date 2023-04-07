// ignore_for_file: avoid_print, avoid_slow_async_io, only_throw_errors

import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:args/command_runner.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:vosk_flutter/src/cli/options.dart';
import 'package:vosk_flutter/src/cli/target_os_type.dart';

void main(List<String> arguments) {
  CommandRunner<void>(
    'dart run vosk_cli',
    'Vosk CLI for loading native libraries',
  )
    ..addCommand(_InstallCommand())
    ..run(arguments).catchError((Object error) {
      if (error is UsageException) {
        print(error);
        exit(64); // Exit code 64 indicates a usage error.
      }
      throw error;
    });
}

class _InstallCommand extends Command<void> {
  _InstallCommand() {
    populateOptionsParser(argParser);
  }

  static const libVersion = '0.3.45';
  static const versionFileName = 'vosk_version.txt';
  static const packageName = 'vosk_flutter';

  @override
  final description =
      'Download & install Vosk native binaries into a Flutter project';

  @override
  final name = 'install';

  late Options options;

  String getBinaryTargetPath(String voskPackagePath) {
    switch (options.targetOsType!) {
      case TargetOsType.linux:
        return path.join(voskPackagePath, 'linux', 'libs');
      case TargetOsType.windows:
        return path.join(voskPackagePath, 'windows', 'libs');
    }
  }

  String getBinaryUrl() {
    switch (options.targetOsType!) {
      case TargetOsType.linux:
        return 'https://github.com/alphacep/vosk-api/releases/download/v$libVersion/vosk-linux-x86_64-$libVersion.zip';
      case TargetOsType.windows:
        return 'https://github.com/alphacep/vosk-api/releases/download/v$libVersion/vosk-win64-$libVersion.zip';
    }
  }

  Future<bool> shouldSkipInstall(Pubspec voskPubspec) async {
    final pubspecFile = await File('pubspec.yaml').readAsString();
    final projectPubspec = Pubspec.parse(pubspecFile);

    if (packageName == projectPubspec.name) {
      print(
        'Running install command inside ${projectPubspec.name} package which '
        'is the development package for VOSK.\n Skipping download as it '
        'is expected that you build the packages manually.',
      );
      return true;
    }

    if (voskPubspec.publishTo == 'none') {
      print(
        "Referencing $packageName@${voskPubspec.version} which hasn't been "
        'published (publish_to: none). Skipping download.',
      );
      return true;
    }

    return false;
  }

  Future<bool> shouldSkipDownload(
    String binariesPath,
    String expectedVersion,
  ) async {
    final versionsFile = File(path.join(binariesPath, versionFileName));
    if (await versionsFile.exists()) {
      final existingVersion = await versionsFile.readAsString();
      if (expectedVersion == existingVersion) {
        print(
          'Vosk binaries v$libVersion for $packageName@$expectedVersion '
          'already downloaded',
        );
        return true;
      }
    }
    return false;
  }

  Future<void> downloadAndExtractBinaries(
    Directory destinationDir,
  ) async {
    if (await shouldSkipDownload(destinationDir.absolute.path, libVersion)) {
      return;
    }

    if (!await destinationDir.exists()) {
      await destinationDir.create(recursive: true);
    }

    final binaryUrl = getBinaryUrl();
    final archiveName = path.basename(binaryUrl);
    final destinationFile = File(
      path.join(
        Directory.systemTemp.createTempSync('vosk-binary-').absolute.path,
        archiveName,
      ),
    );
    if (!await destinationFile.parent.exists()) {
      await destinationFile.parent.create(recursive: true);
    }

    print(
      'Downloading Vosk binaries v$libVersion '
      'to ${destinationFile.absolute.path}',
    );
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(binaryUrl));
      final response = await request.close();
      if (response.statusCode >= 400) {
        throw Exception(
          'Error downloading Vosk binaries from $binaryUrl. '
          'Error code: ${response.statusCode}',
        );
      }
      await response.pipe(destinationFile.openWrite());
    }
    // TODO(sergsavchuk): Handle download errors in Install command catch
    finally {
      client.close(force: true);
    }

    print('Extracting Vosk binaries to ${destinationDir.absolute.path}');
    await extractFileToDisk(
      destinationFile.absolute.path,
      destinationDir.absolute.path,
    );

    final extractedDirectory = path.join(
      destinationDir.absolute.path,
      path.basenameWithoutExtension(binaryUrl),
    );
    for (final filesystemEntity in Directory(extractedDirectory).listSync()) {
      filesystemEntity.renameSync(
        path.join(
          destinationDir.absolute.path,
          path.basename(filesystemEntity.absolute.path),
        ),
      );
    }

    final versionFile =
        File(path.join(destinationDir.absolute.path, versionFileName));
    await versionFile.writeAsString(libVersion);
  }

  Future<String> getVoskPackagePath() async {
    final packageConfig = await findPackageConfig(Directory.current);
    if (packageConfig == null) {
      throw Exception('Package configuration not found. '
          "Run the 'dart run $packageName install` command from "
          'the root directory of your application');
    }

    final packages = packageConfig.packages.where((p) => p.name == packageName);
    final package = packages.isEmpty ? null : packages.first;
    if (package == null) {
      throw Exception(
        '$packageName package not found in dependencies. '
        'Add $packageName package to your pubspec.yaml',
      );
    }

    if (package.root.scheme != 'file') {
      throw Exception(
        '$packageName package uri ${package.root} is not supported. Uri should start with file://',
      );
    }

    final packagePath = path.join(package.root.toFilePath(), 'pubspec.yaml');
    return packagePath;
  }

  Future<Pubspec> parsePubspec(String path) async {
    try {
      return Pubspec.parse(await File(path).readAsString());
    } on Exception catch (e) {
      throw Exception('Error parsing package pubspec at $path. Error $e');
    }
  }

  @override
  FutureOr<void> run() async {
    options = parseOptionsResult(argResults!);
    validateOptions();

    final voskPackagePath = await getVoskPackagePath();
    final voskPubspec = await parsePubspec(voskPackagePath);

    if (await shouldSkipInstall(voskPubspec)) {
      return;
    }

    final binaryPath =
        Directory(getBinaryTargetPath(path.dirname(voskPackagePath)));
    await downloadAndExtractBinaries(binaryPath);

    print('Vosk install command finished.');
  }

  void validateOptions() {
    if (options.targetOsType == null) {
      abort('Invalid target OS: null.');
    }
  }

  void abort(String error) {
    print(error);
    print(usage);
    exit(64); // usage error
  }
}
