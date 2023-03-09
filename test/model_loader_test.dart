import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:vosk_flutter/src/model_loader.dart';

class MockClient extends Mock implements http.Client {}

class MockAssetBundle extends Mock implements AssetBundle {}

void main() {
  const testModelName = 'test_model_name';
  const modelStorage = 'build/model_loader_test';
  final http.Client client = MockClient();
  final AssetBundle assetBundle = MockAssetBundle();
  late final ModelLoader modelLoader;
  late final Uint8List modelBytes;
  const modelsJson = '''
    [
      {
          "lang": "ar",
          "lang_text": "Arabic",
          "md5": "1ff29ab1d313f2c95079b41bf2e95fba",
          "name": "vosk-model-ar-0.22-linto-1.1.0",
          "obsolete": "false",
          "size": 1377395170,
          "size_text": "1.3GiB",
          "type": "big",
          "url": "https://alphacephei.com/vosk/models/vosk-model-ar-0.22-linto-1.1.0.zip",
          "version": "0.22-linto-1.1.0"
      },
      {
          "lang": "ar",
          "lang_text": "Arabic",
          "md5": "d912e25ce46f94fe362b8c98e5efb4fd",
          "name": "vosk-model-ar-mgb2-0.4",
          "obsolete": "true",
          "size": 333241610,
          "size_text": "317.8MiB",
          "type": "big",
          "url": "https://alphacephei.com/vosk/models/vosk-model-ar-mgb2-0.4.zip",
          "version": "mbg2-0.4"
      }
    ]
  ''';

  setUpAll(() {
    modelLoader = ModelLoader(
      modelStorage: modelStorage,
      httpClient: client,
      assetBundle: assetBundle,
    );

    final archive = Archive()
      ..addFile(ArchiveFile.string('$testModelName/$testModelName.file', ''));

    modelBytes = Uint8List.fromList(ZipEncoder().encode(archive)!);
    when(() => assetBundle.load(any()))
        .thenAnswer((_) async => modelBytes.buffer.asByteData());
  });

  tearDown(() {
    if (Directory(modelStorage).existsSync()) {
      Directory(modelStorage).deleteSync(recursive: true);
    }
  });

  group('ModelLoader', () {
    test('Loads a list of models from a remote server', () async {
      registerFallbackValue(Uri.parse(''));
      when(() => client.get(any()))
          .thenAnswer((_) async => http.Response(modelsJson, 200));

      final modelsList = await modelLoader.loadModelsList();
      expect(modelsList.length, 2);
    });

    test('Returns correct model path', () async {
      expect(
        await modelLoader.modelPath(testModelName),
        equals(path.join(modelStorage, testModelName)),
      );
    });

    test('Loads a model from assets', () async {
      final modelPath =
          await modelLoader.loadFromAssets('assets/models/$testModelName');

      expect(
        Directory(modelPath).existsSync(),
        equals(true),
        reason: "File $modelPath doesn't exist",
      );
    });

    test('Loads a model from the network', () async {
      registerFallbackValue(Uri.parse(''));
      when(() => client.get(any()))
          .thenAnswer((_) async => http.Response.bytes(modelBytes, 200));

      final modelPath = await modelLoader.loadFromNetwork(
        'https://alphacephei.com/vosk/models/$testModelName.zip',
      );

      expect(
        Directory(modelPath).existsSync(),
        equals(true),
        reason: "File $modelPath doesn't exist",
      );
    });

    test('Returns true when model is already loaded', () async {
      await modelLoader.loadFromAssets('assets/models/$testModelName');
      expect(await modelLoader.isModelAlreadyLoaded(testModelName), true);
    });

    test('Returns false when model is not loaded', () async {
      expect(await modelLoader.isModelAlreadyLoaded(testModelName), false);
    });
  });
}
