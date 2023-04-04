import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

void main() {
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
    test('Throws an error when the model path is wrong', () async {
      expect(vosk.createModel('wrong/model/path'),
          throwsA(isInstanceOf<String>()));
    });

    test('Creates a model from the data located on the specified path',
        () async {
      final model = await vosk.createModel(enSmallModelPath);
      expect(model.path, equals(enSmallModelPath));
    });

    test('Creates a recognizer using a model', () async {
      final model = await vosk.createModel(enSmallModelPath);
      expect(vosk.createRecognizer(model: model, sampleRate: sampleRate),
          completes);
    });
  });

  group('Recognizer', () {
    const grammar = ['one', 'zero'];
    late Model model;
    late Uint8List audioBytes;
    late Recognizer recognizer;

    setUpAll(() async {
      model = await vosk.createModel(enSmallModelPath);
      audioBytes =
          (await rootBundle.load('assets/audio/test.wav')).buffer.asUint8List();
    });

    setUp(() async {
      recognizer = await vosk.createRecognizer(
        model: model,
        sampleRate: sampleRate,
      );
    });

    test('Recognizes audio data', () async {
      const expectedResults = [
        'one zero zero zero one',
        'nah no to i know',
        'zero one eight zero three'
      ];
      final results = (await recognizeAudio(audioBytes, recognizer))
          .map((result) => jsonDecode(result)['text'])
          .toList();

      expectEqualRecognitionResults(results, expectedResults);
    });

    test('Recognizes audio data using predefined grammar', () async {
      const expectedResults = [
        'one zero zero zero one',
        'zero',
        'zero one zero zero'
      ];
      final recognizerWithGrammar = await vosk.createRecognizer(
        model: model,
        sampleRate: sampleRate,
        grammar: grammar,
      );
      final results = (await recognizeAudio(audioBytes, recognizerWithGrammar))
          .map((result) => jsonDecode(result)['text'])
          .toList();

      expectEqualRecognitionResults(results, expectedResults);
    });

    test('Constructor grammar and #setGrammar give same result', () async {
      final recognizerWithConstructorGrammar = await vosk.createRecognizer(
        model: model,
        sampleRate: sampleRate,
        grammar: grammar,
      );
      final recognizerWithSetGrammar = await vosk.createRecognizer(
        model: model,
        sampleRate: sampleRate,
      );
      await recognizerWithSetGrammar.setGrammar(grammar);

      final constructorResults = await recognizeAudio(
        audioBytes,
        recognizerWithConstructorGrammar,
      );
      final setGrammarResults = await recognizeAudio(
        audioBytes,
        recognizerWithSetGrammar,
      );

      expectEqualRecognitionResults(constructorResults, setGrammarResults);
    });

    test('Returns results with alternatives when #setMaxAlternatives used',
        () async {
      await recognizer.setMaxAlternatives(2);
      final results = await recognizeAudio(audioBytes, recognizer);

      expect(results[0], contains('alternatives'));
    });

    test('Returns results with words when #setWords used', () async {
      await recognizer.setWords(words: true);
      final results = await recognizeAudio(audioBytes, recognizer);

      expect(results[0], contains('word'));
    });

    test('Returns partial results with words when #setPartialWords used',
        () async {
      await recognizer.setPartialWords(partialWords: true);
      await recognizer.acceptWaveformBytes(audioBytes);
      final partialResult = await recognizer.getPartialResult();

      expect(partialResult, contains('word'));
    });

    test('Resets results when #reset used', () async {
      await recognizer.acceptWaveformBytes(audioBytes);
      await recognizer.reset();

      final partialResult = await recognizer.getPartialResult();

      expect(jsonDecode(partialResult)['text'], equals(''));
    });
  });
}

void expectEqualRecognitionResults(List results, List<String> expectedResults) {
  expect(listEquals(results, expectedResults), true,
      reason: 'Actual results: $results\nExpected results: $expectedResults');
}

Future<List<String>> recognizeAudio(
    Uint8List audioBytes, Recognizer recognizer) async {
  List<String> results = [];
  int chunkSize = 8192;
  int pos = 0;

  while (pos + chunkSize < audioBytes.length) {
    final resultReady = await recognizer.acceptWaveformBytes(
        Uint8List.fromList(audioBytes.getRange(pos, pos + chunkSize).toList()));
    pos += chunkSize;

    if (resultReady) {
      results.add(await recognizer.getResult());
    }
  }
  await recognizer.acceptWaveformBytes(
      Uint8List.fromList(audioBytes.getRange(pos, audioBytes.length).toList()));
  results.add(await recognizer.getFinalResult());

  return results;
}
