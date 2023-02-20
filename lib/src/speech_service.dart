import 'dart:async';

import 'package:flutter/services.dart';

class SpeechService {
  SpeechService(this._channel);

  final MethodChannel _channel;

  Stream<String>? _resultStream;
  Stream<String>? _partialResultStream;
  StreamSubscription<void>? _errorStreamSubscription;

  Future<bool?> start({required Function onRecognitionError}) {
    _errorStreamSubscription ??= EventChannel(
      'error_event_channel',
      const StandardMethodCodec(),
      _channel.binaryMessenger,
    ).receiveBroadcastStream().listen(null, onError: onRecognitionError);

    return _channel.invokeMethod<bool>('speechService.start');
  }

  Future<bool?> stop() {
    _errorStreamSubscription?.cancel();
    return _channel.invokeMethod<bool>('speechService.stop');
  }

  Future<bool?> setPause(bool paused) =>
      _channel.invokeMethod<bool>('speechService.setPause', paused);

  Future<bool?> reset() => _channel.invokeMethod<bool>('speechService.reset');

  Future<bool?> cancel() {
    _errorStreamSubscription?.cancel();
    return _channel.invokeMethod<bool>('speechService.cancel');
  }

  Future<void> destroy() {
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
