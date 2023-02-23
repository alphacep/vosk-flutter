package org.vosk.vosk_flutter_plugin;

public class RecognizerNotFound extends Exception {

  public RecognizerNotFound(Integer recognizerId) {
    super(String.format("Recognizer with id=%s doesn't exist", recognizerId.toString()));
  }
}
