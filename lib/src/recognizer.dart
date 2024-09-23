import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:vosk_flutter/src/generated_vosk_bindings.dart';
import 'package:vosk_flutter/src/utils.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

/// Class representing the recognizer created by the plugin.
class Recognizer {
  /// Use [VoskFlutterPlugin.createRecognizer] to create a [Recognizer]
  /// instance.
  Recognizer({
    required this.id,
    required this.model,
    required this.sampleRate,
    required MethodChannel channel,
    this.recognizerPointer,
    VoskLibrary? voskLibrary,
  })  : _channel = channel,
        _voskLibrary = voskLibrary;

  /// Unique id of the recognizer.
  final int id;

  /// Vosk model containing static data for the recognizer. Model can be shared
  /// across recognizers.
  final Model model;

  /// The sample rate of the audio you are going to feed into the recognizer.
  final int sampleRate;
  final MethodChannel _channel;

  /// Pointer to a native recognizer object.
  final Pointer<VoskRecognizer>? recognizerPointer;
  final VoskLibrary? _voskLibrary;

  /// Configures recognizer to output n-best results.
  Future<void> setMaxAlternatives(int maxAlternatives) {
    if (_voskLibrary != null) {
      _voskLibrary.vosk_recognizer_set_max_alternatives(
        recognizerPointer!,
        maxAlternatives,
      );
      return Future.value();
    }

    return _invokeRecognizerMethod<void>(
      'setMaxAlternatives',
      {'maxAlternatives': maxAlternatives},
    );
  }

  /// Enables/disables words with times in the output of the [getResult].
  Future<void> setWords({required bool words}) {
    if (_voskLibrary != null) {
      _voskLibrary.vosk_recognizer_set_words(
        recognizerPointer!,
        words ? 1 : 0,
      );
      return Future.value();
    }

    return _invokeRecognizerMethod<void>('setWords', {'words': words});
  }

  /// Same as [setWords] but for [getPartialResult].
  Future<void> setPartialWords({required bool partialWords}) {
    if (_voskLibrary != null) {
      _voskLibrary.vosk_recognizer_set_partial_words(
        recognizerPointer!,
        partialWords ? 1 : 0,
      );
      return Future.value();
    }

    return _invokeRecognizerMethod<void>(
      'setPartialWords',
      {'partialWords': partialWords},
    );
  }

  /// Accept and process new chunk of voice data(audio data in PCM 16-bit
  /// mono format).
  Future<bool> acceptWaveformBytes(Uint8List bytes) {
    if (_voskLibrary != null) {
      final result = using((arena) {
        final data = bytes.toCharPtr(arena);
        return _voskLibrary.vosk_recognizer_accept_waveform(
          recognizerPointer!,
          data,
          bytes.length,
        );
      });
      return Future.value(result == 1);
    }

    return _invokeRecognizerMethod<bool>('acceptWaveForm', {'bytes': bytes})
        .then((value) => value!);
  }

  /// Accept and process new chunk of voice data(audio data in PCM 16-bit
  /// mono format).
  Future<bool> acceptWaveformFloats(Float32List floats) {
    if (_voskLibrary != null) {
      final result = using((arena) {
        final data = floats.toFloatPtr(arena);
        return _voskLibrary.vosk_recognizer_accept_waveform_f(
          recognizerPointer!,
          data,
          floats.length,
        );
      });

      return Future.value(result == 1);
    }

    return _invokeRecognizerMethod<bool>('acceptWaveForm', {'floats': floats})
        .then((value) => value!);
  }

  /// Returns speech recognition result.
  /// If alternatives enabled it returns result with alternatives, see
  /// [setMaxAlternatives].
  /// If word times enabled returns word time, see also [setWords].
  Future<String> getResult() {
    if (_voskLibrary != null) {
      final result = _voskLibrary.vosk_recognizer_result(recognizerPointer!);
      return Future.value(result.toDartString());
    }

    return _invokeRecognizerMethod<String>('getResult')
        .then((value) => value ?? '{}');
  }

  /// Returns partial speech recognition.
  /// If alternatives enabled it returns result with alternatives, see
  /// [setMaxAlternatives].
  /// If word times enabled returns word time, see also [setWords].
  Future<String> getPartialResult() {
    if (_voskLibrary != null) {
      final result =
          _voskLibrary.vosk_recognizer_partial_result(recognizerPointer!);
      return Future.value(result.toDartString());
    }

    return _invokeRecognizerMethod<String>('getPartialResult')
        .then((value) => value ?? '{}');
  }

  /// Returns speech recognition result. Same as result, but doesn't wait for
  /// silence. You usually call it in the end of the stream to get final bits
  /// of audio. It flushes the feature pipeline, so all remaining audio chunks
  /// got processed.
  Future<String> getFinalResult() {
    if (_voskLibrary != null) {
      final result =
          _voskLibrary.vosk_recognizer_final_result(recognizerPointer!);
      return Future.value(result.toDartString());
    }

    return _invokeRecognizerMethod<String>('getFinalResult')
        .then((value) => value ?? '{}');
  }

  /// Reconfigures recognizer to use grammar.
  Future<void> setGrammar(List<String> grammar) {
    if (_voskLibrary != null) {
      using((arena) {
        final grammarString = jsonEncode(grammar).toCharPtr(arena);
        _voskLibrary.vosk_recognizer_set_grm(
          recognizerPointer!,
          grammarString,
        );
      });
      return Future.value();
    }

    return _invokeRecognizerMethod<void>(
      'setGrammar',
      {'grammar': jsonEncode(grammar)},
    );
  }

  /// Resets current results so the recognition can continue from scratch.
  Future<void> reset() {
    if (_voskLibrary != null) {
      _voskLibrary.vosk_recognizer_reset(recognizerPointer!);
      return Future.value();
    }

    return _invokeRecognizerMethod<void>('reset');
  }

  /// Releases recognizer object.
  /// Underlying model is also unreferenced and if needed, released.
  Future<void> dispose() {
    if (_voskLibrary != null) {
      _voskLibrary.vosk_recognizer_free(recognizerPointer!);
      return Future.value();
    }

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
