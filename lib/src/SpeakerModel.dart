import 'dart:ffi';

import 'package:flutter/services.dart';
import 'package:vosk_flutter/src/generated_vosk_bindings.dart';

/// Class representing the speaker model loaded by the plugin.
class SpeakerModel {
  /// Use [VoskFlutterPlugin.createSpeakerModel] to create a [SpeakerModel] instance.
  SpeakerModel(this.path, this._channel,
      [this.modelPointer, this._voskLibrary]);

  /// Location of this speaker model in the file system.
  final String path;

  /// Pointer to a native speaker model object.
  final Pointer<VoskSpkModel>? modelPointer;

  final VoskLibrary? _voskLibrary;

  // ignore:unused_field
  final MethodChannel _channel;

  /// Free all model resources.
  void dispose() {
    if (_voskLibrary != null) {
      _voskLibrary!.vosk_spk_model_free(modelPointer!);
    }
  }

  @override
  String toString() {
    return 'SpeakerModel[path=$path, pointer=$modelPointer]';
  }
}
