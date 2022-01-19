# vosk_flutter_plugin

Flutter plugin for Vosk speech recognition.

## How to use

### Configurations
Add this pro guard rules in ...android/app directory/proguard-rules.pro
```
-keep class com.sun.jna.* { *; }
-keepclassmembers class * extends com.sun.jna.* { public *; }
```

Add this plugin to pubspec.yaml
```vosk_flutter_plugin:```

### Load and init model
```
ByteData modelZip = await rootBundle.load('assets/models/vosk-model-small-en-us-0.15.zip');
await VoskFlutterPlugin.initModel(modelZip);
```

### Start recognition
```
VoskFlutterPlugin.start();
```

### Stop recognition
```
VoskFlutterPlugin.stop();
```

