import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:vosk_flutter_plugin/vosk_flutter_plugin.dart';

class Recognizer {
  Recognizer({
    required this.id,
    required this.model,
    required this.sampleRate,
    required MethodChannel channel,
  }) : _channel = channel;

  final int id;
  final Model model;
  final int sampleRate;
  final MethodChannel _channel;

  Future<void> setMaxAlternatives(int maxAlternatives) {
    return _invokeRecognizerMethod<void>(
      'setMaxAlternatives',
      {'maxAlternatives': maxAlternatives},
    );
  }

  Future<void> setWords(bool words) {
    return _invokeRecognizerMethod<void>('setWords', {'words': words});
  }

  Future<void> setPartialWords(bool partialWords) {
    return _invokeRecognizerMethod<void>(
      'setPartialWords',
      {'partialWords': partialWords},
    );
  }

  Future<bool?> acceptWaveformBytes(Uint8List bytes) {
    return _invokeRecognizerMethod<bool>('acceptWaveForm', {'bytes': bytes});
  }

  Future<bool?> acceptWaveformFloats(Float32List floats) {
    return _invokeRecognizerMethod<bool>('acceptWaveForm', {'floats': floats});
  }

  Future<String?> getResult() {
    return _invokeRecognizerMethod<String>('getResult');
  }

  Future<String?> getPartialResult() {
    return _invokeRecognizerMethod<String>('getPartialResult');
  }

  Future<String?> getFinalResult() {
    return _invokeRecognizerMethod<String>('getFinalResult');
  }

  Future<void> setGrammar(List<String> grammar) {
    return _invokeRecognizerMethod<void>(
      'setGrammar',
      {'grammar': jsonEncode(grammar)},
    );
  }

  Future<void> reset() {
    return _invokeRecognizerMethod<void>('reset');
  }

  Future<void> close() {
    return _invokeRecognizerMethod<void>('close');
  }

  Future<T?> _invokeRecognizerMethod<T>(
    String method, [
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
