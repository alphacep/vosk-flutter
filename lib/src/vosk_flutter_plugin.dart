import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vosk_flutter_plugin/src/model.dart';
import 'package:vosk_flutter_plugin/src/model_loader.dart';
import 'package:vosk_flutter_plugin/src/recognizer.dart';
import 'package:vosk_flutter_plugin/src/speech_service.dart';

/// Provides access to the Vosk speech recognition API.
class VoskFlutterPlugin {
  VoskFlutterPlugin._() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  /// Get plugin instance.
  ///
  /// ignore:prefer_constructors_over_static_methods
  static VoskFlutterPlugin instance() => _instance ??= VoskFlutterPlugin._();

  static const MethodChannel _channel = MethodChannel('vosk_flutter_plugin');
  static VoskFlutterPlugin? _instance;

  late final Map<String, Completer<Model>> _pendingModels = {};

  /// Create a model from model data located at the [modelPath].
  /// See [ModelLoader]
  Future<Model> createModel(String modelPath) {
    final completer = Completer<Model>();
    _pendingModels[modelPath] = completer;

    _channel.invokeMethod('model.create', modelPath);
    return completer.future;
  }

  /// Create a recognizer that will use the specified [model] to process
  /// speech. [sampleRate] determines the sample rate of the audio fed to the
  /// recognizer(a mismatch in the sample rate causes accuracy problems).
  ///
  /// You can optionally provide [grammar] for the recognizer, see
  /// [Recognizer.setGrammar] for more details about the grammar usage.
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

  /// Init a speech service that will use the provided [recognizer] to process
  /// audio input from the device microphone.
  ///
  /// This method may throw [MicrophoneAccessDeniedException].
  Future<SpeechService> initSpeechService(Recognizer recognizer) async {
    if (await Permission.microphone.status == PermissionStatus.denied &&
        await Permission.microphone.request() == PermissionStatus.denied) {
      throw MicrophoneAccessDeniedException();
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
      case 'model.error':
        final modelPath = call.arguments['modelPath'] as String;
        final error = call.arguments['error'] as String;
        _pendingModels.remove(modelPath)?.completeError(error);
        break;
      default:
        log('Unsupported method: ${call.method}', name: 'VOSK_PLUGIN');
    }
  }
}

/// An exception thrown when the user denies access to the microphone.
class MicrophoneAccessDeniedException implements Exception {}
