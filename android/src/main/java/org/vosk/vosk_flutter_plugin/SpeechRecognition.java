package org.vosk.vosk_flutter_plugin;

import org.vosk.Model;
import org.vosk.Recognizer;
import org.vosk.android.RecognitionListener;
import org.vosk.android.SpeechService;

import java.io.IOException;
import java.util.concurrent.Callable;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;

public class SpeechRecognition implements RecognitionListener {
    private Model model;
    private SpeechService speechService;

    private EventChannel.EventSink resultEvent;
    private EventChannel.EventSink partialEvent;
    private EventChannel.EventSink finalResultEvent;

    private final EventChannel resultEventChannel;
    private final EventChannel partialEventChannel;
    private final EventChannel finalResultEventChannel;

    private TaskRunner taskRunner;

    SpeechRecognition(FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        resultEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "RESULT_EVENT");
        partialEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "PARTIAL_RESULT_EVENT");
        finalResultEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "FINAL_RESULT_EVENT");
        initEventChannels();
    }

    ///Load and init model
    void initModel(String pathModel) {
        if (taskRunner == null) {
            taskRunner = new TaskRunner();
        }

        if (pathModel == null) {
            return;
        }

        try {
            taskRunner.executeAsync(new SetupModel(pathModel), result -> model = result);
        } catch(Exception e) {
            throw new RuntimeException(e);
        }
//        model = new Model(pathModel);
    }

    private static class SetupModel implements Callable<Model> {
        private final String path;

        public SetupModel(String path) {
            this.path = path;
        }

        @Override
        public Model call() {
            return new Model(path);
        }
    }

    ///Start recognition
    public void start() throws IOException {
        // If the speech is already running, cancel it.
        if (speechService != null) {
            speechService.cancel();
            speechService = null;
        }

        if (model == null) {
            throw new IOException("Model not loaded. Model may not be downloaded yet, or has the wrong path in the filesystem.");
        }
        Recognizer recognizer = new Recognizer(model, 16000.0f);
        speechService = new SpeechService(recognizer, 16000.0f);
        speechService.startListening(this);
    }

    ///Stop recognition
    public void stop() throws IOException {
        if (speechService != null) {
            speechService.stop();
            speechService.shutdown();
        }

        if (model == null) {
            throw new IOException("Model not loaded. Model may not be downloaded yet, or has the wrong path in the filesystem.");
        }
    }

    @Override
    public void onPartialResult(String hypothesis) {
        if (partialEvent != null) {
            partialEvent.success(hypothesis);
        }
    }

    @Override
    public void onResult(String hypothesis) {
        if (resultEvent != null) {
            resultEvent.success(hypothesis);
        }
    }

    @Override
    public void onFinalResult(String hypothesis) {
        if (finalResultEvent != null) {
            finalResultEvent.success(hypothesis);
        }
    }

    @Override
    public void onError(Exception exception) {
        if (resultEvent != null) {
            resultEvent.error("Runtime Exception", exception.getMessage(), exception);
        }

        if (partialEvent != null) {
            partialEvent.error("Runtime Exception", exception.getMessage(), exception);
        }

        if (finalResultEventChannel != null) {
            finalResultEvent.error("Runtime Exception", exception.getMessage(), exception);
        }
    }

    @Override
    public void onTimeout() {

    }

    private void initEventChannels() {
        resultEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                resultEvent = events;
            }

            @Override
            public void onCancel(Object arguments) {
                resultEvent = null;
            }
        });

        partialEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                partialEvent = events;
            }

            @Override
            public void onCancel(Object arguments) {
                partialEvent = null;
            }
        });

        finalResultEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                finalResultEvent = events;
            }

            @Override
            public void onCancel(Object arguments) {
                finalResultEvent = null;
            }
        });

    }

    public void dispose() {
        resultEventChannel.setStreamHandler(null);
        partialEventChannel.setStreamHandler(null);
        finalResultEventChannel.setStreamHandler(null);
    }

}