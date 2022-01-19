
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class VoskFlutterPlugin {
  static const MethodChannel _channel = MethodChannel('vosk_flutter_plugin');
  static const EventChannel _resultMessageChannel = EventChannel('RESULT_EVENT');
  static const EventChannel _partialMessageChannel = EventChannel('PARTIAL_RESULT_EVENT');
  static const EventChannel _finalResultMessageChannel = EventChannel('FINAL_RESULT_EVENT');
  static bool _isLoaded = false;
  static String status = '';

  static Future<void> initModel(ByteData modelZip) async {
    status = 'iniciando';
    String modelPath = await _decompressModel(modelZip);
    // status = modelPath;
    String result = await _channel.invokeMethod('initModel', modelPath);
    status = 'modelo iniciado';
    log(result, name: 'INIT VOSK MODEL');
    _isLoaded = true;
  }

  static Future<void> start() async {
    if (_isLoaded) {
      String result = await _channel.invokeMethod('start');
      log(result, name: 'START VOSK RECOGNITION');
    } else {
      log('NO MODEL LOADED', name: 'START VOSK RECOGNITION');
    }
  }

  static Future<void> stop() async {
    if (_isLoaded) {
      String result = await _channel.invokeMethod('stop');
      log(result, name: 'STOP VOSK RECOGNITION');
    } else {
      log('NO MODEL LOADED', name: 'STOP VOSK RECOGNITION');
    }
  }

  static Stream onResult() {
    return _resultMessageChannel.receiveBroadcastStream();
  }

  static Stream onProcess() async* {
    yield status;
  }

  static Stream onPartial() {
    return _partialMessageChannel.receiveBroadcastStream();
  }

  static Stream onFinalResult() {
    return _finalResultMessageChannel.receiveBroadcastStream();
  }

  static Future<String> _decompressModel(ByteData zipModelFile) async {

    // Decode the Zip file
    final archive = ZipDecoder().decodeBytes(zipModelFile.buffer.asUint8List());

    String decompressedModelPathOut = (await getApplicationDocumentsDirectory()).path;
    decompressedModelPathOut = '$decompressedModelPathOut/models';

    // Extract the contents of the Zip archive to disk.
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        File(decompressedModelPathOut + '/' + filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        log(decompressedModelPathOut + '/' + filename, name: 'EN EL ZIP');
        Directory(decompressedModelPathOut + '/' + filename).create(recursive: true);
      }
    }
    String rootDirectory = '$decompressedModelPathOut/${archive.first.name.replaceAll(RegExp(r'/'), '')}';
    log(rootDirectory, name: 'MODEL DIRECTORY');
    return rootDirectory;
  }

  ///deprecated
  static Future<File> _writeToFile(ByteData data) async {
    String path = (await getTemporaryDirectory()).path + '/model_temp.zip';
    final buffer = data.buffer;
    return File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }
}
