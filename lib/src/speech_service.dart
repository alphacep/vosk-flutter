import 'package:flutter/services.dart';

class SpeechService {
  SpeechService(this._channel);

  static const EventChannel _resultMessageChannel =
      EventChannel('RESULT_EVENT');
  static const EventChannel _partialMessageChannel =
      EventChannel('PARTIAL_RESULT_EVENT');
  static const EventChannel _finalResultMessageChannel =
      EventChannel('FINAL_RESULT_EVENT');

  final MethodChannel _channel;

  Future<bool?> start() {
    return _channel.invokeMethod<bool>('speechService.start');
  }

  Future<bool?> stop() {
    return _channel.invokeMethod<bool>('speechService.stop');
  }

  Future<bool?> setPause(bool paused) {
    return _channel.invokeMethod<bool>('speechService.setPause', paused);
  }

  Future<bool?> reset() {
    return _channel.invokeMethod<bool>('speechService.reset');
  }

  Future<bool?> cancel() {
    return _channel.invokeMethod<bool>('speechService.cancel');
  }

  Future<void> destroy() {
    return _channel.invokeMethod<void>('speechService.destroy');
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
