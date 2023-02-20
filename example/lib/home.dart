import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vosk_flutter_plugin/vosk_flutter_plugin.dart';

const modelAsset = 'assets/models/vosk-model-small-en-us-0.15.zip';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String modelCreateResult = "model.create result: ";

  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  Model? model;
  bool modelLoading = false;

  Recognizer? recognizer;
  SpeechService? speechService;

  String _grammar = 'hello world foo boo';
  int _maxAlternatives = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vosk Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: ListView(
          children: [
            Text("Model: $model"),
            btn('model.create', _modelCreate, color: Colors.orange),
            const Divider(color: Colors.grey, thickness: 1),
            Text("Recognizer: $recognizer"),
            btn('recognizer.create', _recognizerCreate, color: Colors.green),
            Row(
              children: [
                Flexible(
                  child: btn('recognizer.setMaxAlternatives',
                      _recognizerSetMaxAlternatives,
                      color: Colors.green),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    _maxAlternatives.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
                Flexible(
                  child: Slider(
                    value: _maxAlternatives.toDouble(),
                    min: 0,
                    max: 3,
                    divisions: 3,
                    onChanged: (val) => setState(() {
                      _maxAlternatives = val.toInt();
                    }),
                  ),
                )
              ],
            ),
            btn('recognizer.setWords', _recognizerSetWords,
                color: Colors.green),
            btn('recognizer.setPartialWords', _recognizerSetPartialWords,
                color: Colors.green),
            Row(
              children: [
                Flexible(
                  child: btn('recognizer.setGrammar', _recognizerSetGrammar,
                      color: Colors.green),
                ),
                const SizedBox(width: 20),
                Flexible(
                  child: TextField(
                    style: const TextStyle(color: Colors.black),
                    controller: TextEditingController(text: _grammar),
                    onChanged: (val) => setState(() {
                      _grammar = val;
                    }),
                  ),
                )
              ],
            ),
            btn('recognizer.acceptWaveForm', _recognizerAcceptWaveForm,
                color: Colors.green),
            btn('recognizer.getResult', _recognizerGetResult,
                color: Colors.green),
            btn('recognizer.getPartialResult', _recognizerGetPartialResult,
                color: Colors.green),
            btn('recognizer.getFinalResult', _recognizerGetFinalResult,
                color: Colors.green),
            btn('recognizer.reset', _recognizerReset, color: Colors.green),
            btn('recognizer.close', _recognizerClose, color: Colors.green),
            const Divider(color: Colors.grey, thickness: 1),
            Text("SpeechService: $speechService"),
            btn('speechService.init', _initSpeechService,
                color: Colors.lightBlueAccent),
            btn('speechService.start', _speechServiceStart,
                color: Colors.lightBlueAccent),
            btn('speechService.stop', _speechServiceStop,
                color: Colors.lightBlueAccent),
            btn('speechService.setPause', _speechServiceSetPause,
                color: Colors.lightBlueAccent),
            btn('speechService.reset', _speechServiceReset,
                color: Colors.lightBlueAccent),
            btn('speechService.cancel', _speechServiceCancel,
                color: Colors.lightBlueAccent),
            btn('speechService.destroy', _speechServiceDestroy,
                color: Colors.lightBlueAccent),
            const SizedBox(height: 20),
            if (speechService != null)
              StreamBuilder(
                  stream: speechService?.onPartial(),
                  builder: (_, snapshot) =>
                      Text('Partial: ' + snapshot.data.toString())),
            if (speechService != null)
              StreamBuilder(
                  stream: speechService?.onResult(),
                  builder: (_, snapshot) =>
                      Text('Result: ' + snapshot.data.toString())),
            if (speechService != null)
              StreamBuilder(
                  stream: speechService?.onFinalResult(),
                  builder: (_, snapshot) =>
                      Text('Final: ' + snapshot.data.toString())),
          ],
        ),
      ),
    );
  }

  Widget btn(String text, VoidCallback onPressed, {Color? color}) {
    return ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
        style: ButtonStyle(backgroundColor: MaterialStateProperty.all(color)));
  }

  void _toastFutureError(Future<Object?> future) => future
      .onError((error, _) => Fluttertoast.showToast(msg: error.toString()));

  void _modelCreate() async {
    if (model != null) {
      Fluttertoast.showToast(msg: 'The model is already loaded');
      return;
    }

    if (modelLoading) {
      Fluttertoast.showToast(msg: 'The model is loading right now');
      return;
    }
    modelLoading = true;

    _toastFutureError(_vosk
        .createModel(await ModelLoader().loadFromAssets(modelAsset))
        .then((value) => setState(() => model = value)));
  }

  void _recognizerCreate() async {
    final localModel = model;
    if (localModel == null) {
      Fluttertoast.showToast(msg: 'Create the model first');
      return;
    }

    _toastFutureError(_vosk
        .createRecognizer(model: localModel, sampleRate: 16000)
        .then((value) => setState(() => recognizer = value)));
  }

  void _recognizerSetMaxAlternatives() async {
    final localRecognizer = recognizer;
    if (localRecognizer == null) {
      Fluttertoast.showToast(msg: 'Create the recognizer first');
      return;
    }

    _toastFutureError(localRecognizer.setMaxAlternatives(_maxAlternatives));
  }

  void _recognizerSetWords() async {
    final localRecognizer = recognizer;
    if (localRecognizer == null) {
      Fluttertoast.showToast(msg: 'Create the recognizer first');
      return;
    }

    _toastFutureError(localRecognizer.setWords(true));
  }

  void _recognizerSetPartialWords() async {
    final localRecognizer = recognizer;
    if (localRecognizer == null) {
      Fluttertoast.showToast(msg: 'Create the recognizer first');
      return;
    }

    _toastFutureError(localRecognizer.setPartialWords(true));
  }

  void _recognizerSetGrammar() async {
    final localRecognizer = recognizer;
    if (localRecognizer == null) {
      Fluttertoast.showToast(msg: 'Create the recognizer first');
      return;
    }

    _toastFutureError(localRecognizer.setGrammar(_grammar.split(' ')));
  }

  void _recognizerAcceptWaveForm() async {
    final localRecognizer = recognizer;
    if (localRecognizer == null) {
      Fluttertoast.showToast(msg: 'Create the recognizer first');
      return;
    }

    _toastFutureError(localRecognizer
        .acceptWaveformBytes((await rootBundle.load('assets/audio/test.wav'))
            .buffer
            .asUint8List())
        .then((value) => Fluttertoast.showToast(msg: value.toString())));
  }

  void _recognizerGetResult() async {
    final localRecognizer = recognizer;
    if (localRecognizer == null) {
      Fluttertoast.showToast(msg: 'Create the recognizer first');
      return;
    }

    _toastFutureError(localRecognizer
        .getResult()
        .then((value) => Fluttertoast.showToast(msg: value.toString())));
  }

  void _recognizerGetPartialResult() async {
    final localRecognizer = recognizer;
    if (localRecognizer == null) {
      Fluttertoast.showToast(msg: 'Create the recognizer first');
      return;
    }

    _toastFutureError(localRecognizer
        .getPartialResult()
        .then((value) => Fluttertoast.showToast(msg: value.toString())));
  }

  void _recognizerGetFinalResult() async {
    final localRecognizer = recognizer;
    if (localRecognizer == null) {
      Fluttertoast.showToast(msg: 'Create the recognizer first');
      return;
    }

    _toastFutureError(localRecognizer
        .getFinalResult()
        .then((value) => Fluttertoast.showToast(msg: value.toString())));
  }

  void _recognizerReset() async {
    final localRecognizer = recognizer;
    if (localRecognizer == null) {
      Fluttertoast.showToast(msg: 'Create the recognizer first');
      return;
    }

    _toastFutureError(localRecognizer.reset());
  }

  void _recognizerClose() async {
    final localRecognizer = recognizer;
    if (localRecognizer == null) {
      Fluttertoast.showToast(msg: 'Create the recognizer first');
      return;
    }

    _toastFutureError(localRecognizer.close().then((_) => recognizer = null));
  }

  void _initSpeechService() async {
    final localRecognizer = recognizer;
    if (localRecognizer == null) {
      Fluttertoast.showToast(msg: 'Create the recognizer first');
      return;
    }

    _toastFutureError(_vosk
        .initSpeechService(localRecognizer)
        .then((value) => setState(() => speechService = value)));
  }

  void _speechServiceStart() async {
    final localSpeechService = speechService;
    if (localSpeechService == null) {
      Fluttertoast.showToast(msg: 'Create the speech service first');
      return;
    }

    _toastFutureError(localSpeechService
        .start()
        .then((value) => Fluttertoast.showToast(msg: value.toString())));
  }

  void _speechServiceStop() async {
    final localSpeechService = speechService;
    if (localSpeechService == null) {
      Fluttertoast.showToast(msg: 'Create the speech service first');
      return;
    }

    _toastFutureError(localSpeechService
        .stop()
        .then((value) => Fluttertoast.showToast(msg: value.toString())));
  }

  void _speechServiceSetPause() async {
    final localSpeechService = speechService;
    if (localSpeechService == null) {
      Fluttertoast.showToast(msg: 'Create the speech service first');
      return;
    }

    _toastFutureError(localSpeechService.setPause(true));
  }

  void _speechServiceReset() async {
    final localSpeechService = speechService;
    if (localSpeechService == null) {
      Fluttertoast.showToast(msg: 'Create the speech service first');
      return;
    }

    _toastFutureError(localSpeechService.reset());
  }

  void _speechServiceCancel() async {
    final localSpeechService = speechService;
    if (localSpeechService == null) {
      Fluttertoast.showToast(msg: 'Create the speech service first');
      return;
    }

    _toastFutureError(localSpeechService
        .cancel()
        .then((value) => Fluttertoast.showToast(msg: value.toString())));
  }

  void _speechServiceDestroy() async {
    final localSpeechService = speechService;
    if (localSpeechService == null) {
      Fluttertoast.showToast(msg: 'Create the speech service first');
      return;
    }

    _toastFutureError(localSpeechService.destroy());
  }
}
