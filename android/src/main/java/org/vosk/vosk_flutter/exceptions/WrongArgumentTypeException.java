package org.vosk.vosk_flutter.exceptions;

public class WrongArgumentTypeException extends Exception {

  public WrongArgumentTypeException(Class<?> actual, Class<?> expected, String source) {
    super(String.format("%s has wrong type, expected: %s, actual: %s", source, expected.getName(),
        actual.getName()));
  }
}
