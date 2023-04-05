import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

import 'common_test.dart' as common_test;

void main() {
  common_test.main();

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const sampleRate = 16000;
  late VoskFlutterPlugin vosk;
  late String enSmallModelPath;

  setUpAll(() async {
    vosk = VoskFlutterPlugin.instance();
    enSmallModelPath = await ModelLoader()
        .loadFromAssets('assets/models/vosk-model-small-en-us-0.15.zip');
  });

  group('VoskFlutterPlugin', () {
    test('Creates a speech service using a recognizer and destroys it',
        () async {
      final model = await vosk.createModel(enSmallModelPath);
      final recognizer = await vosk.createRecognizer(
        model: model,
        sampleRate: sampleRate,
      );

      final speechService = await vosk.initSpeechService(recognizer);
      expect(speechService.dispose(), completes);
    });
  });

  group('SpeechService', () {
    late SpeechService speechService;

    setUp(() async {
      final model = await vosk.createModel(enSmallModelPath);
      final recognizer = await vosk.createRecognizer(
        model: model,
        sampleRate: sampleRate,
      );
      speechService = await vosk.initSpeechService(recognizer);
    });

    tearDown(() async {
      speechService.cancel();
      speechService.dispose();
    });

    test("Doesn't emit any results until #start called", () async {
      expect(speechService.onPartial().first, doesNotComplete);
    });

    test("Emits results after #start called", () async {
      await speechService.start();
      expect(speechService.onPartial().first, completes);
    });

    test("Doesn't emit any results after #stop called", () async {
      await speechService.start();
      await speechService.stop();
      expect(speechService.onPartial().first, doesNotComplete);
    });

    test("Doesn't emit any results after #cancel called", () async {
      await speechService.start();
      await speechService.cancel();
      expect(speechService.onPartial().first, doesNotComplete);
    });

    test("Emits results after #start when canceled", () async {
      await speechService.start();
      await speechService.cancel();
      await speechService.start();
      expect(speechService.onPartial().first, completes);
    });

    test("Doesn't emit any results after #setPause(true) called", () async {
      await speechService.start();
      await speechService.setPause(paused: true);
      expect(speechService.onPartial().first, doesNotComplete);
    });

    test("Emits results after #setPause(false) called", () async {
      await speechService.start();
      await speechService.setPause(paused: true);
      await speechService.setPause(paused: false);
      expect(speechService.onPartial().first, completes);
    });
  });
}
