package org.vosk.vosk_flutter_plugin;

public class ArgumentNotFoundException extends Exception{
  public ArgumentNotFoundException(String argumentName){
    super(String.format("Couldn't find argument \"%s\" in map.", argumentName));
  }
}
