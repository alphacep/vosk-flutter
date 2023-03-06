# vosk_flutter_plugin

[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![vosk_flutter](https://github.com/alphacep/vosk-flutter/actions/workflows/vosk_flutter.yml/badge.svg)](https://github.com/alphacep/vosk-flutter/actions/workflows/vosk_flutter.yml)

Flutter plugin for Vosk speech recognition.

## Platform Support

| Android | iOS | MacOS | Web | Linux | Windows |
| :-----: | :-: | :---: | :-: | :---: | :----: |
|   ✔    | ➖  |  ➖   | ➖  |  ➖   |   ➖   |

## Usage

### Configurations
Add this pro guard rules in `android/app/proguard-rules.pro`
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

If you want to use microphone input, add microphone permission to your `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### Load model
```dart
final vosk = VoskFlutterPlugin.instance();
final enSmallModelPath = await ModelLoader()
    .loadFromAssets('assets/models/vosk-model-small-en-us-0.15.zip');
```

### Create recognizer
```dart
final recognizer = await vosk.createRecognizer(
    model: model,
    sampleRate: sampleRate,
);
final recognizerWithGrammar = await vosk.createRecognizer(
    model: model,
    sampleRate: sampleRate,
    grammar: ['one', 'two', 'three'],
);
```

### Recognize audio data
```dart
Uint8List audioBytes = ...; // audio data in PCM 16-bit mono format
List<String> results = [];
int chunkSize = 8192;
int pos = 0;

while (pos + chunkSize < audioBytes.length) {
    final resultReady = await recognizer.acceptWaveformBytes(
      Uint8List.fromList(audioBytes.getRange(pos, pos + chunkSize).toList()));
    pos += chunkSize;
    
    if (resultReady) {
      print(await recognizer.getResult());
    } else {
      print(await recognizer.getPartialResult());
    }
}
await recognizer.acceptWaveformBytes(
  Uint8List.fromList(audioBytes.getRange(pos, audioBytes.length).toList()));
print(await recognizer.getFinalResult());
```

### Recognize microphone data
```dart
final speechService = await vosk.initSpeechService(recognizer);
speechService.onPartial().forEach((partial) => print(partial));
speechService.onResult().forEach((result) => print(result));
await speechService.start();
```
