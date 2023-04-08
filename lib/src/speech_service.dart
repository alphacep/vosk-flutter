import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vosk_flutter/src/recognizer.dart';

/// Speech recognition service used to process audio input from the provided
/// audio data stream.
class SpeechService {
  /// Create a new [SpeechService] that will use the provided [_recognizer] for
  /// speech recognition.
  SpeechService(this._recognizer);

  final Recognizer _recognizer;
  StreamSubscription<Uint8List>? _micSubscription;

  final StreamController<String> _resultStreamController =
      StreamController.broadcast();
  final StreamController<String> _partialResultStreamController =
      StreamController.broadcast();

  /// Whether the recognition is paused.
  bool paused = false;

  /// Start recognition of the provided [audioStream].
  /// [audioStream] must be in PCM 16-bit mono format.
  /// Use [onResult] and [onPartial] to get recognition results.
  /// Returns false if already started.
  bool start(Stream<Uint8List> audioStream) {
    if (_micSubscription != null) {
      return false;
    }

    paused = false;
    _micSubscription = audioStream.listen((bytes) {
      if (paused) {
        return;
      }

      if (_recognizer.acceptWaveformBytes(bytes)) {
        _resultStreamController.add(_recognizer.getResult());
      } else {
        _partialResultStreamController.add(_recognizer.getPartialResult());
      }
    });
    return true;
  }

  /// Stop recognition.
  /// Returns false if already stopped.
  bool stop() {
    if (_micSubscription == null) {
      return false;
    }

    _micSubscription?.cancel();
    _micSubscription = null;

    if (!paused) {
      _resultStreamController.add(_recognizer.getFinalResult());
    }

    return true;
  }

  /// Reset recognition.
  /// See [Recognizer.reset].
  void reset() => _recognizer.reset();

  /// Stop recognition, but don't emit final result.
  /// Returns false if already started.
  bool cancel() {
    if (_micSubscription != null) {
      paused = true;
    }

    return stop();
  }

  /// Get stream with voice recognition results.
  Stream<String> onResult() => _resultStreamController.stream;

  /// Get stream with voice recognition partial results.
  Stream<String> onPartial() => _partialResultStreamController.stream;
}
