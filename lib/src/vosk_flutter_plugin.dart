import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';

/// Provides access to the Vosk speech recognition API.
class VoskFlutterPlugin {
  VoskFlutterPlugin._() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  static VoskFlutterPlugin? _instance;

  /// Now you can only get one vosk instance
  ///
  /// ignore:prefer_constructors_over_static_methods
  static VoskFlutterPlugin instance() => _instance ??= VoskFlutterPlugin._();

  static const MethodChannel _channel = MethodChannel('vosk_flutter_plugin');
  static const EventChannel _resultMessageChannel =
      EventChannel('RESULT_EVENT');
  static const EventChannel _partialMessageChannel =
      EventChannel('PARTIAL_RESULT_EVENT');
  static const EventChannel _finalResultMessageChannel =
      EventChannel('FINAL_RESULT_EVENT');
  static const String _voskLogName = 'VOSK';

  bool _initialized = false;
  VoidCallback? _initCallback;

  Future<void> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'init':
        _initialized = true;
        _initCallback?.call();
        break;
      default:
        log('Unsupported method: ${call.method}');
    }
  }

  /// Initialize Vosk with language model.
  /// [initCallback] will be called when initialization finishes.
  Future<void> initModel({
    required String modelPath,
    VoidCallback? initCallback,
  }) async {
    _initCallback = initCallback;
    await _channel.invokeMethod('initModel', modelPath);
  }

  /// Start voice recognition.
  /// You should call [initModel] first and wait until initialization finished.
  /// Use [onResult], [onPartial], [onFinalResult] to get recognition data.
  Future<void> start() async {
    if (_initialized) {
      final result = await _channel.invokeMethod('start');
      log(result.toString(), name: _voskLogName);
    } else {
      log('Skipping start(): call initModel() first', name: _voskLogName);
    }
  }

  /// Stop voice recognition.
  Future<void> stop() async {
    if (_initialized) {
      final result = await _channel.invokeMethod('stop');
      log(result.toString(), name: 'STOP VOSK RECOGNITION');
    } else {
      log('NO MODEL LOADED', name: 'STOP VOSK RECOGNITION');
    }
  }

  /// Get stream with voice recognition results.
  Stream<String> onResult() {
    return _resultMessageChannel
        .receiveBroadcastStream()
        .map((result) => result.toString());
  }

  /// Get stream with voice recognition partial results.
  Stream<String> onPartial() {
    return _partialMessageChannel
        .receiveBroadcastStream()
        .map((result) => result.toString());
  }

  /// Get stream with voice recognition final results.
  Stream<String> onFinalResult() {
    return _finalResultMessageChannel
        .receiveBroadcastStream()
        .map((result) => result.toString());
  }
}
