# vosk_flutter_plugin

[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

Flutter plugin for Vosk speech recognition.

## How to use

### Configurations
Add this pro guard rules in ...android/app/proguard-rules.pro
If the file does not exist create it.
```properties
-keep class com.sun.jna.* { *; }
-keepclassmembers class * extends com.sun.jna.* { public *; }
```

Add this plugin to pubspec.yaml
```yaml
vosk_flutter_plugin:
  git: https://github.com/alphacep/vosk-flutter
```

### Load and init model
```dart
bool loaded = false;
final vosk = VoskFlutterPlugin();
ByteData modelZip = await rootBundle.load('assets/models/vosk-model-small-en-us-0.15.zip');
vosk.initModel(modelZip, initCallback: () => loaded = true);
```

### Start recognition
```dart
if (loaded) {
  VoskFlutterPlugin.start();
}
```

### Stop recognition
```dart
VoskFlutterPlugin.stop();
```

### Listen to results
```dart
StreamBuilder(
  stream: VoskFlutterPlugin.onPartial(),
  builder: (context, snapshot) => Text(snapshot.data.toString()),
),

StreamBuilder(
  stream: VoskFlutterPlugin.onResult(),
  builder: (context, snapshot) => Text(snapshot.data.toString()),
),

StreamBuilder(
  stream: VoskFlutterPlugin.onFinalResult(),
  builder: (context, snapshot) => Text(snapshot.data.toString()),
),
```

