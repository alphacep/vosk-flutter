package org.vosk.vosk_flutter_plugin;

public class WrongTypeException extends Exception{
  public WrongTypeException(String actual, String expected){
    super(String.format("Wrong argument type, you sent \"%s\", expected \"%s\"", actual, expected));
  }
}
