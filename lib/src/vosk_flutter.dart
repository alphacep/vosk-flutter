import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vosk_flutter/src/generated_vosk_bindings.dart';
import 'package:vosk_flutter/src/utils.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

/// Provides access to the Vosk speech recognition API.
class VoskFlutterPlugin {
  VoskFlutterPlugin._() {
    if (_supportsFFI()) {
      _voskLibrary = _loadVoskLibrary();
    } else if (Platform.isAndroid) {
      _channel.setMethodCallHandler(_methodCallHandler);
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

  static const MethodChannel _channel = MethodChannel('vosk_flutter');
  static VoskFlutterPlugin? _instance;

  late final Map<String, Completer<Model>> _pendingModels = {};

  /// Create a model from model data located at the [modelPath].
  /// See [ModelLoader]
  Future<Model> createModel(String modelPath) {
    final completer = Completer<Model>();

    if (_supportsFFI()) {
      compute(_loadModel, modelPath).then(
        (modelPointer) => completer.complete(
          Model(modelPath, _channel, Pointer.fromAddress(modelPointer)),
        ),
        onError: completer.completeError,
      );
    } else if (Platform.isAndroid) {
      _pendingModels[modelPath] = completer;
      _channel.invokeMethod('model.create', modelPath);
    }
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
    if (_supportsFFI()) {
      return using((arena) {
        final recognizerPointer = grammar == null
            ? _voskLibrary.vosk_recognizer_new(
                model.modelPointer!,
                sampleRate.toDouble(),
              )
            : _voskLibrary.vosk_recognizer_new_grm(
                model.modelPointer!,
                sampleRate.toDouble(),
                jsonEncode(grammar).toCharPtr(arena),
              );
        return Recognizer(
          id: -1,
          model: model,
          sampleRate: sampleRate,
          channel: _channel,
          recognizerPointer: recognizerPointer,
          voskLibrary: _voskLibrary,
        );
      });
    }

    final args = <String, dynamic>{
      'modelPath': model.path,
      'sampleRate': sampleRate,
    };
    if (grammar != null) {
      args['grammar'] = jsonEncode(grammar);
    }
    final id = await _channel.invokeMethod('recognizer.create', args);
    return Recognizer(
      id: id as int,
      model: model,
      sampleRate: sampleRate,
      channel: _channel,
    );
  }

  /// Init a speech service that will use the provided [recognizer] to process
  /// audio input from the device microphone.
  ///
  /// This method may throw [MicrophoneAccessDeniedException].
  Future<SpeechService> initSpeechService(Recognizer recognizer) async {
    if (await Permission.microphone.status == PermissionStatus.denied &&
        await Permission.microphone.request() == PermissionStatus.denied) {
      throw MicrophoneAccessDeniedException();
    }

    await _channel.invokeMethod('speechService.init', {
      'recognizerId': recognizer.id,
      'sampleRate': recognizer.sampleRate,
    });
    return SpeechService(_channel);
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'model.created':
        final modelPath = call.arguments as String;
        _pendingModels.remove(modelPath)?.complete(Model(modelPath, _channel));
        break;
      case 'model.error':
        final args = call.arguments as Map;
        final modelPath = args['modelPath'] as String;
        final error = args['error'] as String;
        _pendingModels.remove(modelPath)?.completeError(error);
        break;
      default:
        log('Unsupported method: ${call.method}', name: 'VOSK_PLUGIN');
    }
  }

  bool _supportsFFI() => Platform.isLinux || Platform.isWindows;

  static VoskLibrary _loadVoskLibrary() {
    String libraryPath;
    if (Platform.isLinux) {
      libraryPath = Platform.environment['LIBVOSK_PATH']!;
    } else if (Platform.isWindows) {
      libraryPath = 'libvosk.dll';
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

/// An exception thrown when the user denies access to the microphone.
class MicrophoneAccessDeniedException implements Exception {}
