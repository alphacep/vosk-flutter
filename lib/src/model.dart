import 'package:flutter/services.dart';

class Model {
  Model(this.path, this._channel);

  final String path;
  final MethodChannel _channel;

  @override
  String toString() {
    return 'Model[path=$path]';
  }
}
