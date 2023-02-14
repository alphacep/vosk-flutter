import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:vosk_flutter_plugin/vosk_flutter_plugin.dart';
import 'package:vosk_flutter_plugin_example/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> initModel() async {
    await VoskFlutterPlugin.instance().initModel(
        modelPath: await ModelLoader()
            .loadFromAssets('assets/models/vosk-model-small-en-us-0.15.zip'));
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}
