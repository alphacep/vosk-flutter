package org.vosk.vosk_flutter;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import org.vosk.android.RecognitionListener;

public class FlutterRecognitionListener implements RecognitionListener {

  private final EventChannel errorEventChannel;
  private final EventChannel resultEventChannel;
  private final EventChannel partialEventChannel;

  private EventChannel.EventSink errorSink;
  private EventChannel.EventSink resultSink;
  private EventChannel.EventSink partialSink;

  public FlutterRecognitionListener(BinaryMessenger binaryMessenger) {
    errorEventChannel = new EventChannel(binaryMessenger, "error_event_channel");
    resultEventChannel = new EventChannel(binaryMessenger, "result_event_channel");
    partialEventChannel = new EventChannel(binaryMessenger, "partial_event_channel");

    errorEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object arguments, EventSink events) {
        errorSink = events;
      }

      @Override
      public void onCancel(Object arguments) {
        errorSink = null;
      }
    });

    resultEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object arguments, EventChannel.EventSink events) {
        resultSink = events;
      }

      @Override
      public void onCancel(Object arguments) {
        resultSink = null;
      }
    });

    partialEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object arguments, EventChannel.EventSink events) {
        partialSink = events;
      }

      @Override
      public void onCancel(Object arguments) {
        partialSink = null;
      }
    });
  }

  @Override
  public void onPartialResult(String hypothesis) {
    if (partialSink != null) {
      partialSink.success(hypothesis);
    }
  }

  @Override
  public void onResult(String hypothesis) {
    if (resultSink != null) {
      resultSink.success(hypothesis);
    }
  }

  @Override
  public void onFinalResult(String hypothesis) {
    if (resultSink != null) {
      resultSink.success(hypothesis);
    }
  }

  @Override
  public void onError(Exception exception) {
    if (errorSink != null) {
      errorSink.error("RECOGNITION_ERROR", exception.getMessage(), exception);
    }
  }

  @Override
  public void onTimeout() {
  }

  public void dispose() {
    errorEventChannel.setStreamHandler(null);
    resultEventChannel.setStreamHandler(null);
    partialEventChannel.setStreamHandler(null);
  }
}
