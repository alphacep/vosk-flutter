package org.vosk.vosk_flutter.exceptions;

public class RecognizerNotFound extends Exception {

  public RecognizerNotFound(Integer recognizerId) {
    super(String.format("Recognizer with id=%s doesn't exist", recognizerId.toString()));
  }
}
