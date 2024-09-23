import 'dart:ffi';

import 'package:flutter/services.dart';
import 'package:vosk_flutter/src/generated_vosk_bindings.dart';
import 'package:vosk_flutter/src/vosk_flutter.dart';

/// Class representing the language model loaded by the plugin.
class Model {
  /// Use [VoskFlutterPlugin.createModel] to create a [Model] instance.
  Model(this.path, this._channel, [this.modelPointer, this._voskLibrary]);

  /// Location of this model in the file system.
  final String path;

  /// Pointer to a native model object.
  final Pointer<VoskModel>? modelPointer;

  final VoskLibrary? _voskLibrary;

  // ignore:unused_field
  final MethodChannel _channel;

  /// Free all model resources.
  void dispose() {
    if (_voskLibrary != null) {
      _voskLibrary.vosk_model_free(modelPointer!);
    }
  }

  @override
  String toString() {
    return 'Model[path=$path, pointer=$modelPointer]';
  }
}
