import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vosk_flutter_plugin/vosk_flutter_plugin.dart';
import 'package:vosk_flutter_plugin_example/home.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await runZonedGuarded<Future<void>>(() async {
    await FirebaseCrashlytics.instance.recordError('INICIANDO APP', null);
    runApp(const MyApp());
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack));

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
    return const MaterialApp(
      home: Home(),
    );
  }
}
