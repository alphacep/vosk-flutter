@Timeout(Duration(seconds: 45))

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

import 'common_test.dart' as common_test;

class MockMethodChannel extends Mock implements MethodChannel {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final binding = TestDefaultBinaryMessengerBinding.instance;
  const MethodChannel channel = MethodChannel('vosk_flutter');

  // We will simulate EventChannel messages by sending platform messages
  // on the EventChannel name the plugin uses ('partial_event_channel').
  // Pending event id to allow cancelling scheduled events when paused/stopped
  int _pendingEventCounter = 0;

  setUpAll(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      debugPrint('MockMethodCallHandler invoked: \\${call.method}');
      switch (call.method) {
        case 'speechService.init':
          debugPrint('Mocking speechService.init');
          return {'recognizerId': 'mockId', 'sampleRate': 16000};
        case 'speechService.start':
          debugPrint('Mocking speechService.start');
          // Simulate an EventChannel partial result event slightly after
          // start so subscribers created after start still receive it.
          final int id = ++_pendingEventCounter;
          Future.delayed(const Duration(milliseconds: 50), () {
            if (id != _pendingEventCounter) return; // cancelled by stop/pause
            try {
              final data = const StandardMethodCodec()
                  .encodeSuccessEnvelope('partial result');
              binding.defaultBinaryMessenger.handlePlatformMessage(
                'partial_event_channel',
                data,
                (_) {},
              );
            } catch (e) {
              debugPrint('Error sending partial event: $e');
            }
          });
          return null;
        case 'speechService.stop':
        case 'speechService.cancel':
        case 'speechService.destroy':
          debugPrint('Mocking \\${call.method}');
          // Cancel any pending scheduled events
          _pendingEventCounter++;
          return null;
        case 'speechService.setPause':
          debugPrint('Mocking speechService.setPause');
          // Support both a boolean argument or a map {"paused": bool}
          bool paused;
          if (call.arguments is bool) {
            paused = call.arguments as bool;
          } else if (call.arguments is Map) {
            paused = (call.arguments as Map)['paused'] as bool? ?? false;
          } else {
            paused = false;
          }
          if (paused) {
            // Pause: cancel any pending events and do not send further events
            _pendingEventCounter++;
          } else {
            // Delay slightly so any new subscriber can attach
            final int id2 = ++_pendingEventCounter;
            Future.delayed(const Duration(milliseconds: 50), () {
              if (id2 != _pendingEventCounter) {
                return; // cancelled in the meantime
              }
              try {
                final data = const StandardMethodCodec()
                    .encodeSuccessEnvelope('partial result after resume');
                binding.defaultBinaryMessenger.handlePlatformMessage(
                  'partial_event_channel',
                  data,
                  (_) {},
                );
              } catch (_) {}
            });
          }
          return null;
        default:
          debugPrint('Unimplemented method: \\${call.method}');
          throw PlatformException(
            code: 'Unimplemented',
            details: 'Method \\${call.method} not implemented.',
          );
      }
    });
  });

  // No global teardown required for mocked platform messages.

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
