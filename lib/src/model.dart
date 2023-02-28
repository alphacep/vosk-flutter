import 'package:flutter/services.dart';
import 'package:vosk_flutter_plugin/src/vosk_flutter_plugin.dart';

/// Class representing the language model loaded by the plugin.
class Model {
  /// Use [VoskFlutterPlugin.createModel] to create a [Model] instance.
  Model(this.path, this._channel);

  /// Location of this model in the file system.
  final String path;

  // ignore:unused_field
  final MethodChannel _channel;

  @override
  String toString() {
    return 'Model[path=$path]';
  }
}
