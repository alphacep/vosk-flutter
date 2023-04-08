import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:vosk_flutter/src/generated_vosk_bindings.dart';
import 'package:vosk_flutter/src/utils.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

/// Class representing the recognizer created by the plugin.
class Recognizer {
  /// Use [VoskFlutterPlugin.createRecognizer] to create a [Recognizer]
  /// instance.
  Recognizer({
    required this.model,
    required this.sampleRate,
    required this.recognizerPointer,
    required VoskLibrary voskLibrary,
  }) : _voskLibrary = voskLibrary;

  /// Vosk model containing static data for the recognizer. Model can be shared
  /// across recognizers.
  final Model model;

  /// The sample rate of the audio you are going to feed into the recognizer.
  final int sampleRate;

  /// Pointer to a native recognizer object.
  final Pointer<VoskRecognizer> recognizerPointer;
  final VoskLibrary _voskLibrary;

  /// Configures recognizer to output n-best results.
  void setMaxAlternatives(int maxAlternatives) {
    _voskLibrary.vosk_recognizer_set_max_alternatives(
      recognizerPointer,
      maxAlternatives,
    );
  }

  /// Enables/disables words with times in the output of the [getResult].
  void setWords({required bool words}) {
    _voskLibrary.vosk_recognizer_set_words(
      recognizerPointer,
      words ? 1 : 0,
    );
  }

  /// Same as [setWords] but for [getPartialResult].
  void setPartialWords({required bool partialWords}) {
    _voskLibrary.vosk_recognizer_set_partial_words(
      recognizerPointer,
      partialWords ? 1 : 0,
    );
  }

  /// Accept and process new chunk of voice data(audio data in PCM 16-bit
  /// mono format).
  bool acceptWaveformBytes(Uint8List bytes) {
    final result = using((arena) {
      final data = bytes.toCharPtr(arena);
      return _voskLibrary.vosk_recognizer_accept_waveform(
        recognizerPointer,
        data,
        bytes.length,
      );
    });
    return result == 1;
  }

  /// Accept and process new chunk of voice data(audio data in PCM 16-bit
  /// mono format).
  bool acceptWaveformFloats(Float32List floats) {
    final result = using((arena) {
      final data = floats.toFloatPtr(arena);
      return _voskLibrary.vosk_recognizer_accept_waveform_f(
        recognizerPointer,
        data,
        floats.length,
      );
    });

    return result == 1;
  }

  /// Returns speech recognition result.
  /// If alternatives enabled it returns result with alternatives, see
  /// [setMaxAlternatives].
  /// If word times enabled returns word time, see also [setWords].
  String getResult() {
    final result = _voskLibrary.vosk_recognizer_result(recognizerPointer);
    return result.toDartString() ?? '{}';
  }

  /// Returns partial speech recognition.
  /// If alternatives enabled it returns result with alternatives, see
  /// [setMaxAlternatives].
  /// If word times enabled returns word time, see also [setWords].
  String getPartialResult() {
    final result =
        _voskLibrary.vosk_recognizer_partial_result(recognizerPointer);
    return result.toDartString() ?? '{}';
  }

  /// Returns speech recognition result. Same as result, but doesn't wait for
  /// silence. You usually call it in the end of the stream to get final bits
  /// of audio. It flushes the feature pipeline, so all remaining audio chunks
  /// got processed.
  String getFinalResult() {
    final result = _voskLibrary.vosk_recognizer_final_result(recognizerPointer);
    return result.toDartString() ?? '{}';
  }

  /// Reconfigures recognizer to use grammar.
  void setGrammar(List<String> grammar) {
    using((arena) {
      final grammarString = jsonEncode(grammar).toCharPtr(arena);
      _voskLibrary.vosk_recognizer_set_grm(
        recognizerPointer,
        grammarString,
      );
    });
  }

  /// Resets current results so the recognition can continue from scratch.
  void reset() {
    _voskLibrary.vosk_recognizer_reset(recognizerPointer);
  }

  /// Releases recognizer object.
  /// Underlying model is also unreferenced and if needed, released.
  void dispose() {
    _voskLibrary.vosk_recognizer_free(recognizerPointer);
  }

  @override
  String toString() {
    return 'Recognizer[model=$model, sampleRate=$sampleRate,'
        ' pointer=$recognizerPointer]';
  }
}
