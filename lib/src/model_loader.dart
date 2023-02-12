import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ModelLoader {
  ModelLoader({this.modelStorage});

  static const String _modelsListUrl =
      'https://alphacephei.com/vosk/models/model-list.json';

  final String? modelStorage;

  static Future<String> _defaultDecompressionPath() async =>
      path.join((await getApplicationDocumentsDirectory()).path, 'models');

  Future<String> loadFromAssets(String asset, {bool forceReload = true}) async {
    final modelName = path.basenameWithoutExtension(asset);
    if (!forceReload && await isModelAlreadyLoaded(modelName)) {
      final modelPathValue = await modelPath(modelName);
      log('Model already loaded to $modelPathValue in ', name: 'ModelLoader');
      return modelPathValue;
    }

    final start = DateTime.now();

    final bytes = await rootBundle.load(asset);
    final archive = ZipDecoder().decodeBytes(bytes.buffer.asInt8List());
    final decompressionPath = modelStorage ?? await _defaultDecompressionPath();

    await Isolate.run(() => extractArchiveToDisk(archive, decompressionPath));

    final decompressedModelRoot = path.join(decompressionPath, modelName);
    log(
      'Model loaded to $decompressedModelRoot in '
      '${DateTime.now().difference(start).inMilliseconds}ms',
      name: 'ModelLoader',
    );

    return decompressedModelRoot;
  }

  // need to add permissions
  Future<List<LanguageModelDescription>> loadModelsList() async {
    final responseJson = (await http.get(Uri.parse(_modelsListUrl))).body;
    final jsonList = jsonDecode(responseJson) as List<dynamic>;
    return jsonList
        .map(
          (modelJson) => LanguageModelDescription.fromJson(
            modelJson as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<bool> isModelAlreadyLoaded(String modelName) async {
    final decompressionPath = modelStorage ?? await _defaultDecompressionPath();
    if (Directory(path.join(decompressionPath, modelName)).existsSync()) {
      return true;
    }

    return false;
  }

  Future<String> modelPath(String modelName) async {
    final decompressionPath = modelStorage ?? await _defaultDecompressionPath();
    return path.join(decompressionPath, modelName);
  }
}

class LanguageModelDescription {
  LanguageModelDescription({
    required this.lang,
    required this.langText,
    required this.md5,
    required this.name,
    required this.obsolete,
    required this.size,
    required this.sizeText,
    required this.type,
    required this.url,
    required this.version,
  });

  factory LanguageModelDescription.fromJson(Map<String, dynamic> json) {
    return LanguageModelDescription(
      lang: json['lang'] as String,
      langText: json['lang_text'] as String,
      md5: json['md5'] as String,
      name: json['name'] as String,
      obsolete: json['obsolete'] == 'true',
      size: json['size'] as int,
      sizeText: json['size_text'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      version: json['version'] as String,
    );
  }

  final String lang;
  final String langText;
  final String md5;
  final String name;
  final bool obsolete;
  final int size;
  final String sizeText;
  final String type;
  final String url;
  final String version;
}
