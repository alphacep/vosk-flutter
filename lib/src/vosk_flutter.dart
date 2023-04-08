import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:vosk_flutter/src/generated_vosk_bindings.dart';
import 'package:vosk_flutter/src/utils.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

/// Provides access to the Vosk speech recognition API.
class VoskFlutterPlugin {
  VoskFlutterPlugin._() {
    if (_supportsFFI()) {
      _voskLibrary = _loadVoskLibrary();
    } else {
      throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported',
      );
    }
  }

  late VoskLibrary _voskLibrary;

  /// Get plugin instance.
  ///
  /// ignore:prefer_constructors_over_static_methods
  static VoskFlutterPlugin instance() => _instance ??= VoskFlutterPlugin._();

  static VoskFlutterPlugin? _instance;

  /// Create a model from model data located at the [modelPath].
  /// See [ModelLoader]
  Future<Model> createModel(String modelPath) {
    final completer = Completer<Model>();

    compute(_loadModel, modelPath).then(
      (modelPointer) => completer.complete(
        Model(modelPath, Pointer.fromAddress(modelPointer), _voskLibrary),
      ),
      onError: completer.completeError,
    );

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
    return using((arena) {
      final recognizerPointer = grammar == null
          ? _voskLibrary.vosk_recognizer_new(
              model.modelPointer,
              sampleRate.toDouble(),
            )
          : _voskLibrary.vosk_recognizer_new_grm(
              model.modelPointer,
              sampleRate.toDouble(),
              jsonEncode(grammar).toCharPtr(arena),
            );
      return Recognizer(
        model: model,
        sampleRate: sampleRate,
        recognizerPointer: recognizerPointer,
        voskLibrary: _voskLibrary,
      );
    });
  }

  bool _supportsFFI() =>
      Platform.isLinux || Platform.isWindows || Platform.isAndroid;

  static VoskLibrary _loadVoskLibrary() {
    String libraryPath;
    if (Platform.isLinux) {
      libraryPath = Platform.environment['LIBVOSK_PATH']!;
    } else if (Platform.isWindows) {
      libraryPath = 'libvosk.dll';
    } else if (Platform.isAndroid) {
      libraryPath = 'libvosk.so';
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    final dylib = DynamicLibrary.open(libraryPath);
    return VoskLibrary(dylib);
  }

  /// Method used to load a model in a separate isolate.
  static int _loadModel(String modelPath) {
    final voskLib = _loadVoskLibrary();
    final modelPointer =
        using((arena) => voskLib.vosk_model_new(modelPath.toCharPtr(arena)));

    if (modelPointer == nullptr) {
      // TODO(sergsavchuk): throw a custom error after deletion of the
      // MethodChannel
      // ignore: only_throw_errors
      throw 'Failed to load model';
    }
    return modelPointer.address;
  }
}
