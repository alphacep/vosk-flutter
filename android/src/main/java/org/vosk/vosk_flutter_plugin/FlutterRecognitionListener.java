package org.vosk.vosk_flutter_plugin;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import org.vosk.android.RecognitionListener;

public class FlutterRecognitionListener implements RecognitionListener {
  private EventChannel.EventSink resultEvent;
  private EventChannel.EventSink partialEvent;
  private EventChannel.EventSink finalResultEvent;

  private final EventChannel resultEventChannel;
  private final EventChannel partialEventChannel;
  private final EventChannel finalResultEventChannel;

  public FlutterRecognitionListener(FlutterPlugin.FlutterPluginBinding flutterPluginBinding){
    resultEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(),
        "RESULT_EVENT");
    partialEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(),
        "PARTIAL_RESULT_EVENT");
    finalResultEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(),
        "FINAL_RESULT_EVENT");
    initEventChannels();
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
