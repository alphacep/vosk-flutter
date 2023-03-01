package org.vosk.vosk_flutter_plugin.exceptions;

public class SpeechServiceNotFound extends Exception {

  public SpeechServiceNotFound() {
    super("Speech service not initialized");
  }
}
