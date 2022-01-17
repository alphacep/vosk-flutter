# vosk_flutter_plugin

Flutter plugin for Vosk speech recognition.

## How to use

### Load and init model
ByteData modelZip = await rootBundle.load('assets/models/vosk-model-small-en-us-0.15.zip');
await VoskFlutterPlugin.initModel(modelZip);

### Start recognition
VoskFlutterPlugin.start();

### Stop recognition
VoskFlutterPlugin.stop();

