import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:vosk_flutter_plugin/vosk_flutter_plugin.dart';

/// Class representing the recognizer created by the plugin.
class Recognizer {
  /// Use [VoskFlutterPlugin.createRecognizer] to create a [Recognizer]
  /// instance.
  Recognizer({
    required this.id,
    required this.model,
    required this.sampleRate,
    required MethodChannel channel,
  }) : _channel = channel;

  /// Unique id of the recognizer.
  final int id;

  /// Vosk model containing static data for the recognizer. Model can be shared
  /// across recognizers.
  final Model model;

  /// The sample rate of the audio you are going to feed into the recognizer.
  final int sampleRate;
  final MethodChannel _channel;

  /// Configures recognizer to output n-best results.
  Future<void> setMaxAlternatives(int maxAlternatives) {
    return _invokeRecognizerMethod<void>(
      'setMaxAlternatives',
      {'maxAlternatives': maxAlternatives},
    );
  }

  /// Enables/disables words with times in the output of the [getResult].
  Future<void> setWords({required bool words}) {
    return _invokeRecognizerMethod<void>('setWords', {'words': words});
  }

  /// Same as [setWords] but for [getPartialResult].
  Future<void> setPartialWords({required bool partialWords}) {
    return _invokeRecognizerMethod<void>(
      'setPartialWords',
      {'partialWords': partialWords},
    );
  }

  /// Accept and process new chunk of voice data(audio data in PCM 16-bit
  /// mono format).
  Future<bool> acceptWaveformBytes(Uint8List bytes) {
    return _invokeRecognizerMethod<bool>('acceptWaveForm', {'bytes': bytes})
        .then((value) => value!);
  }

  /// Accept and process new chunk of voice data(audio data in PCM 16-bit
  /// mono format).
  Future<bool> acceptWaveformFloats(Float32List floats) {
    return _invokeRecognizerMethod<bool>('acceptWaveForm', {'floats': floats})
        .then((value) => value!);
  }

  /// Returns speech recognition result.
  /// If alternatives enabled it returns result with alternatives, see
  /// [setMaxAlternatives].
  /// If word times enabled returns word time, see also [setWords].
  Future<String> getResult() {
    return _invokeRecognizerMethod<String>('getResult')
        .then((value) => value ?? '{}');
  }

  /// Returns partial speech recognition.
  /// If alternatives enabled it returns result with alternatives, see
  /// [setMaxAlternatives].
  /// If word times enabled returns word time, see also [setWords].
  Future<String> getPartialResult() {
    return _invokeRecognizerMethod<String>('getPartialResult')
        .then((value) => value ?? '{}');
  }

  /// Returns speech recognition result. Same as result, but doesn't wait for
  /// silence. You usually call it in the end of the stream to get final bits
  /// of audio. It flushes the feature pipeline, so all remaining audio chunks
  /// got processed.
  Future<String> getFinalResult() {
    return _invokeRecognizerMethod<String>('getFinalResult')
        .then((value) => value ?? '{}');
  }

  /// Reconfigures recognizer to use grammar.
  Future<void> setGrammar(List<String> grammar) {
    return _invokeRecognizerMethod<void>(
      'setGrammar',
      {'grammar': jsonEncode(grammar)},
    );
  }

  /// Resets current results so the recognition can continue from scratch.
  Future<void> reset() {
    return _invokeRecognizerMethod<void>('reset');
  }

  /// Releases recognizer object.
  /// Underlying model is also unreferenced and if needed, released.
  Future<void> dispose() {
    return _invokeRecognizerMethod<void>('close');
  }

  Future<T?> _invokeRecognizerMethod<T>(String method, [
    Map<String, dynamic> arguments = const {},
  ]) {
    final args = Map<String, dynamic>.from(arguments);
    args['recognizerId'] = id;
    return _channel.invokeMethod<T>('recognizer.$method', args);
  }

  @override
  String toString() {
    return 'Recognizer[id=$id, model=$model, sampleRate=$sampleRate]';
  }
}
