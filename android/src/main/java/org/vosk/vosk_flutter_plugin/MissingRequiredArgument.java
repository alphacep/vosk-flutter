package org.vosk.vosk_flutter_plugin;

public class MissingRequiredArgument extends Exception {

  public MissingRequiredArgument(String argumentName) {
    super(String.format("Missing required argument \"%s\".", argumentName));
  }
}
