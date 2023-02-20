import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vosk_flutter_plugin/src/model.dart';
import 'package:vosk_flutter_plugin/src/recognizer.dart';
import 'package:vosk_flutter_plugin/src/speech_service.dart';

/// Provides access to the Vosk speech recognition API.
class VoskFlutterPlugin {
  VoskFlutterPlugin._() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  static const MethodChannel _channel = MethodChannel('vosk_flutter_plugin');
  static const String _voskLogName = 'VOSK';

  static VoskFlutterPlugin? _instance;

  /// Get plugin instance.
  ///
  /// ignore:prefer_constructors_over_static_methods
  static VoskFlutterPlugin instance() => _instance ??= VoskFlutterPlugin._();

  late final Map<String, Completer<Model>> _pendingModels = {};

  Future<Model> createModel(String modelPath) {
    final completer = Completer<Model>();
    _pendingModels[modelPath] = completer;

    _channel.invokeMethod('model.create', modelPath);

    return completer.future;
  }

  Future<Recognizer> createRecognizer({
    required Model model,
    required int sampleRate,
    List<String>? grammar,
  }) async {
    final args = <String, dynamic>{
      'modelPath': model.path,
      'sampleRate': sampleRate,
    };
    if (grammar != null) {
      args['grammar'] = jsonEncode(grammar);
    }

    final id = await _channel.invokeMethod('recognizer.create', args);
    return Recognizer(
      id: id as int,
      model: model,
      sampleRate: sampleRate,
      channel: _channel,
    );
  }

  Future<SpeechService> initSpeechService(
    Recognizer recognizer,
  ) async {
    if (await Permission.microphone.request() == PermissionStatus.denied) {
      // TODO(sergsavchuk): create corresponding error class
      throw 'Microphone permission was denied';
    }

    await _channel.invokeMethod('speechService.init', {
      'recognizerId': recognizer.id,
      'sampleRate': recognizer.sampleRate,
    });
    return SpeechService(_channel);
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'model.created':
        final modelPath = call.arguments as String;
        _pendingModels.remove(modelPath)?.complete(Model(modelPath, _channel));
        break;
      default:
        log('Unsupported method: ${call.method}');
    }
  }
}
