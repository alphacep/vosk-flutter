import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vosk_flutter_plugin/vosk_flutter_plugin.dart';

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
    ByteData modelZip = await rootBundle.load('assets/models/vosk-model-small-en-us-0.15.zip');
    await VoskFlutterPlugin.initModel(modelZip);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            const Text('On Partial'),
            StreamBuilder(
              stream: VoskFlutterPlugin.onPartial(),
              builder: (context, snapshot) => Text(snapshot.data.toString()),
            ),


            const Text('On Result'),
            StreamBuilder(
              stream: VoskFlutterPlugin.onResult(),
              builder: (context, snapshot) => Text(snapshot.data.toString()),
            ),


            const Text('On final result'),
            StreamBuilder(
              stream: VoskFlutterPlugin.onFinalResult(),
              builder: (context, snapshot) => Text(snapshot.data.toString()),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => initModel(),
                  child: const Text('Init model')
                ),

                ElevatedButton(
                  onPressed: () => VoskFlutterPlugin.start(),
                  child: const Text('Start recognition')
                ),

                ElevatedButton(
                  onPressed: () => VoskFlutterPlugin.stop(),
                  child: const Text('Stop recognition')
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
