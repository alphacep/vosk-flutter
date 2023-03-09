import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vosk_flutter/src/recognizer.dart';
import 'package:vosk_flutter/src/vosk_flutter.dart';

/// Speech recognition service used to process audio input from the device's
/// microphone.
class SpeechService {
  /// Use [VoskFlutterPlugin.initSpeechService] to create an instance
  /// of [SpeechService].
  SpeechService(this._channel);

  final MethodChannel _channel;

  Stream<String>? _resultStream;
  Stream<String>? _partialResultStream;
  StreamSubscription<void>? _errorStreamSubscription;

  /// Start recognition.
  /// Use [onResult] and [onPartial] to get recognition results.
  Future<bool?> start({Function? onRecognitionError}) {
    _errorStreamSubscription ??= EventChannel(
      'error_event_channel',
      const StandardMethodCodec(),
      _channel.binaryMessenger,
    ).receiveBroadcastStream().listen(null, onError: onRecognitionError);

    return _channel.invokeMethod<bool>('speechService.start');
  }

  /// Stop recognition.
  Future<bool?> stop() {
    _errorStreamSubscription?.cancel();
    return _channel.invokeMethod<bool>('speechService.stop');
  }

  /// Pause/unpause recognition.
  Future<bool?> setPause({required bool paused}) =>
      _channel.invokeMethod<bool>('speechService.setPause', paused);

  /// Reset recognition.
  /// See [Recognizer.reset].
  Future<bool?> reset() => _channel.invokeMethod<bool>('speechService.reset');

  /// Cancel recognition.
  Future<bool?> cancel() {
    _errorStreamSubscription?.cancel();
    return _channel.invokeMethod<bool>('speechService.cancel');
  }

  /// Release service resources.
  Future<void> dispose() {
    _errorStreamSubscription?.cancel();
    return _channel.invokeMethod<void>('speechService.destroy');
  }

  /// Get stream with voice recognition results.
  Stream<String> onResult() => _resultStream ??= EventChannel(
        'result_event_channel',
        const StandardMethodCodec(),
        _channel.binaryMessenger,
      ).receiveBroadcastStream().map((result) => result.toString());

  /// Get stream with voice recognition partial results.
  Stream<String> onPartial() => _partialResultStream ??= EventChannel(
        'partial_event_channel',
        const StandardMethodCodec(),
        _channel.binaryMessenger,
      ).receiveBroadcastStream().map((result) => result.toString());
}
