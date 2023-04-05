import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';
import 'package:path/path.dart';

Future<void> main() async {
  final Map<String, String> envVars = Platform.environment;
  String adbPath = join(
    envVars['ANDROID_SDK_ROOT'] ?? envVars['ANDROID_HOME']!,
    'platform-tools',
    Platform.isWindows ? 'adb.exe' : 'adb',
  );
  await Process.run(adbPath, [
    'shell',
    'pm',
    'grant',
    'org.vosk.vosk_flutter_example',
    'android.permission.RECORD_AUDIO'
  ]);
  await integrationDriver();
}
