import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vosk_flutter_plugin/vosk_flutter_plugin.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isModelLoading = false;
  bool isModelLoaded = false;
  bool isRecognizing = false;

  VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vosk Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              if (!isModelLoaded && !isModelLoading)
                ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isModelLoading = true;
                      });
                      _vosk.initModel(
                          modelPath: await ModelLoader().loadFromAssets(
                              'assets/models/vosk-model-small-en-us-0.15.zip'),
                          initCallback: () => setState(() {
                                isModelLoading = false;
                                isModelLoaded = true;
                              }));
                    },
                    child: const Text('Load and init model')),
              if (isModelLoading) const CircularProgressIndicator(),
              if (isModelLoaded) const Text('Model loaded'),
              ElevatedButton(
                  onPressed: !isRecognizing && isModelLoaded
                      ? () {
                          _vosk.start();
                          setState(() {
                            isRecognizing = true;
                          });
                        }
                      : null,
                  child: const Text('Recognize microphone')),
              ElevatedButton(
                  onPressed: isRecognizing
                      ? () {
                          _vosk.stop();
                          setState(() {
                            isRecognizing = false;
                          });
                        }
                      : null,
                  child: const Text('Stop recognition')),
              const SizedBox(height: 20),
              const Text('On Partial'),
              StreamBuilder(
                stream: _vosk.onPartial(),
                builder: (context, snapshot) => Text(snapshot.data.toString()),
              ),
              const SizedBox(height: 20),
              const Text('On Result'),
              StreamBuilder(
                stream: _vosk.onResult(),
                builder: (context, snapshot) => Text(snapshot.data.toString()),
              ),
              const SizedBox(height: 20),
              const Text('On final result'),
              StreamBuilder(
                stream: _vosk.onFinalResult(),
                builder: (context, snapshot) => Text(snapshot.data.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
