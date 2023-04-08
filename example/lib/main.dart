import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:record/record.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: VoskFlutterDemo(),
    );
  }
}

class VoskFlutterDemo extends StatefulWidget {
  const VoskFlutterDemo({Key? key}) : super(key: key);

  @override
  State<VoskFlutterDemo> createState() => _VoskFlutterDemoState();
}

class _VoskFlutterDemoState extends State<VoskFlutterDemo> {
  static const _textStyle = TextStyle(fontSize: 30, color: Colors.black);
  static const _modelName = 'vosk-model-small-en-us-0.15';
  static const _sampleRate = 16000;

  final _vosk = VoskFlutterPlugin.instance();
  final _modelLoader = ModelLoader();
  final _recorder = Record();

  String? _fileRecognitionResult;
  String? _error;
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  bool _recognitionStarted = false;

  @override
  void initState() {
    super.initState();

    _modelLoader
        .loadModelsList()
        .then((modelsList) =>
            modelsList.firstWhere((model) => model.name == _modelName))
        .then((modelDescription) =>
            _modelLoader.loadFromNetwork(modelDescription.url)) // load model
        .then(
            (modelPath) => _vosk.createModel(modelPath)) // create model object
        .then((model) => setState(() => _model = model))
        .then((_) => _vosk.createRecognizer(
            model: _model!, sampleRate: _sampleRate)) // create recognizer
        .then((value) => _recognizer = value)
        .then((recognizer) {
      if (Platform.isAndroid) {
        _speechService = SpeechService(recognizer);
      }
    }).catchError((e) {
      setState(() => _error = e.toString());
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
          body: Center(child: Text("Error: $_error", style: _textStyle)));
    } else if (_model == null) {
      return const Scaffold(
          body: Center(child: Text("Loading model...", style: _textStyle)));
    } else if (Platform.isAndroid && _speechService == null) {
      return const Scaffold(
        body: Center(
          child: Text("Initializing speech service...", style: _textStyle),
        ),
      );
    } else {
      return Platform.isAndroid ? _micExample() : _recordingExample();
    }
  }

  Widget _micExample() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () async {
                  if (_recognitionStarted) {
                    _speechService!.stop();
                  } else {
                    final micStream = await MicStream.microphone(
                        audioFormat: AudioFormat.ENCODING_PCM_16BIT);
                    if (micStream != null) {
                      _speechService!.start(micStream);
                    } else {
                      _error = "Can't access microphone";
                    }
                  }
                  setState(() => _recognitionStarted = !_recognitionStarted);
                },
                child: Text(_recognitionStarted
                    ? "Stop recognition"
                    : "Start recognition")),
            StreamBuilder(
                stream: _speechService!.onPartial(),
                builder: (context, snapshot) => Text(
                    "Partial result: ${snapshot.data.toString()}",
                    style: _textStyle)),
            StreamBuilder(
                stream: _speechService!.onResult(),
                builder: (context, snapshot) => Text(
                    "Result: ${snapshot.data.toString()}",
                    style: _textStyle)),
          ],
        ),
      ),
    );
  }

  Widget _recordingExample() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () async {
                  if (_recognitionStarted) {
                    await _stopRecording();
                  } else {
                    await _recordAudio();
                  }
                  setState(() => _recognitionStarted = !_recognitionStarted);
                },
                child: Text(
                    _recognitionStarted ? "Stop recording" : "Record audio")),
            Text("Final recognition result: $_fileRecognitionResult",
                style: _textStyle),
          ],
        ),
      ),
    );
  }

  Future<void> _recordAudio() async {
    try {
      await _recorder.start(
          samplingRate: 16000, encoder: AudioEncoder.wav, numChannels: 1);
    } catch (e) {
      _error = e.toString() +
          '\n\n Make sure fmedia(https://stsaz.github.io/fmedia/)'
              ' is installed on Linux';
    }
  }

  Future<void> _stopRecording() async {
    try {
      final filePath = await _recorder.stop();
      if (filePath != null) {
        final bytes = File(filePath).readAsBytesSync();
        _recognizer!.acceptWaveformBytes(bytes);
        _fileRecognitionResult = _recognizer!.getFinalResult();
      }
    } catch (e) {
      _error = e.toString() +
          '\n\n Make sure fmedia(https://stsaz.github.io/fmedia/)'
              ' is installed on Linux';
    }
  }
}
