# vosk_flutter_plugin

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
```

### Load and init model
```dart
ByteData modelZip = await rootBundle.load('assets/models/vosk-model-small-en-us-0.15.zip');
await VoskFlutterPlugin.initModel(modelZip);
```

### Start recognition
```dart
VoskFlutterPlugin.start();
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

