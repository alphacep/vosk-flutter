import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

class RecognizerMock extends Mock implements Recognizer {}

void main() {
  late Recognizer recognizer;
  late SpeechService speechService;

  late final audioDataStreamController =
      StreamController<Uint8List>.broadcast();
  late Timer timer;

  setUpAll(() async {
    recognizer = RecognizerMock();
    registerFallbackValue(Uint8List(0));

    when(() => recognizer.getResult()).thenReturn('result');
    when(() => recognizer.getPartialResult()).thenReturn('partialResult');
    when(() => recognizer.getFinalResult()).thenReturn('finalResult');

    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      audioDataStreamController.add(Uint8List(32000));
    });
  });

  tearDownAll(() {
    timer.cancel();
  });

  setUp(() async {
    speechService = SpeechService(recognizer);

    when(() => recognizer.acceptWaveformBytes(any())).thenReturn(false);
  });

  tearDown(() async {
    speechService.stop();
  });

  group('SpeechService', () {
    test("Doesn't emit any results until #start called", () async {
      expect(speechService.onPartial().first, doesNotComplete);
    });

    test('Emits results after #start called', () async {
      speechService.start(audioDataStreamController.stream);
      expect(speechService.onPartial().first, completes);
    });

    test('Emits result on each chunk of the data', () async {
      final results = <String>[];
      speechService.onPartial().listen(results.add);
      speechService.start(Stream.fromIterable([Uint8List(0), Uint8List(0)]));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(results.length, equals(2));
    });

    test('Emits to onResult() stream when there is silence in the recognition',
        () async {
      when(() => recognizer.acceptWaveformBytes(any())).thenReturn(true);
      speechService.start(audioDataStreamController.stream);

      expect(speechService.onResult().first, completes);
    });

    test("Doesn't emit any results after #stop called", () async {
      speechService
        ..start(audioDataStreamController.stream)
        ..stop();
      expect(speechService.onPartial().first, doesNotComplete);
      expect(speechService.onResult().first, doesNotComplete);
    });

    test('Emits final result when #stop called', () async {
      final result = speechService.onResult().first;
      speechService
        ..start(const Stream.empty())
        ..stop();

      expect(await result, equals('finalResult'));
    });

    test("Doesn't emit any results after #cancel called", () async {
      speechService
        ..start(audioDataStreamController.stream)
        ..cancel();
      expect(speechService.onPartial().first, doesNotComplete);
      expect(speechService.onResult().first, doesNotComplete);
    });

    test("Doesn't emit final result when #cancel called", () async {
      final result = speechService.onResult().first;
      speechService
        ..start(const Stream.empty())
        ..cancel();

      expect(result, doesNotComplete);
    });

    test('Emits results after #start when canceled', () async {
      speechService
        ..start(audioDataStreamController.stream)
        ..cancel()
        ..start(audioDataStreamController.stream);
      expect(speechService.onPartial().first, completes);
    });

    test("Doesn't emit any results after paused set to 'true'", () async {
      speechService
        ..start(audioDataStreamController.stream)
        ..paused = true;
      expect(speechService.onPartial().first, doesNotComplete);
      expect(speechService.onResult().first, doesNotComplete);
    });

    test("Emits results after paused set to 'false'", () async {
      speechService
        ..start(audioDataStreamController.stream)
        ..paused = true
        ..paused = false;
      expect(speechService.onPartial().first, completes);
    });
  });
}
