import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vosk_flutter_plugin/vosk_flutter_plugin.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
  });
}
