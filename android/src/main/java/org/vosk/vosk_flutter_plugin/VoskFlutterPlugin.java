package org.vosk.vosk_flutter_plugin;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.TreeMap;
import org.vosk.Model;
import org.vosk.Recognizer;
import org.vosk.android.SpeechService;

/**
 * VoskFlutterPlugin
 */
public class VoskFlutterPlugin implements FlutterPlugin, MethodCallHandler {

  private static final Class<HashMap<String, Object>> argsMapClass = (Class<HashMap<String, Object>>) new HashMap<String, Object>().getClass();

  private final HashMap<String, Model> modelsMap = new HashMap<>();
  private final TreeMap<Integer, Recognizer> recognizersMap = new TreeMap<>();

  private MethodChannel channel;
  private SpeechService speechService;
  private FlutterRecognitionListener recognitionListener;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "vosk_flutter_plugin");
    channel.setMethodCallHandler(this);
    recognitionListener = new FlutterRecognitionListener(flutterPluginBinding.getBinaryMessenger());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    try {
      switch (call.method) {

        case "model.create": {
          String modelPath = castMethodCallArgs(call, String.class);
          if (modelPath == null) {
            result.error("WRONG_ARGS", "Please, send 1 string argument, contains model path", null);
            break;
          }

          new TaskRunner().executeAsync(() -> new Model(modelPath), (Model model) -> {
            modelsMap.put(modelPath, model);
            channel.invokeMethod("model.created", modelPath);
          }, (Exception exception) -> {
            result.error("MODEL_ERROR", exception.getMessage(), exception);
          });

          result.success(null);
        }
        break;

        case "recognizer.create": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer sampleRate = getRequiredArgumentFromMap(argsMap, "sampleRate", Integer.class);
          String modelPath = getRequiredArgumentFromMap(argsMap, "modelPath", String.class);
          String grammar = getArgumentFromMap(argsMap, "grammar", String.class);

          Model model = modelsMap.get(modelPath);
          if (model == null) {
            result.error("NO_MODEL",
                "Couldn't find model with this path. Pls, create model or send correct path.",
                null);
            break;
          }

          Integer recognizerId = recognizersMap.isEmpty() ? 1 : recognizersMap.lastKey() + 1;
          try {
            Recognizer recognizer =
                argsMap.get("grammar") == null ? new Recognizer(model, sampleRate)
                    : new Recognizer(model, sampleRate, grammar);
            recognizersMap.put(recognizerId, recognizer);
          } catch (IOException e) {
            result.error("CREATION_ERROR", "Can't create recognizer.", e);
            break;
          }

          result.success(recognizerId);
        }
        break;

        case "recognizer.setMaxAlternatives": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          Integer maxAlternatives = getRequiredArgumentFromMap(argsMap, "maxAlternatives",
              Integer.class);

          try {
            recognizersMap.get(recognizerId).setMaxAlternatives(maxAlternatives);
          } catch (NullPointerException e) {
            result.error("NO_RECOGNIZER", "There is no recognizer with this id.", null);
            break;
          }

          result.success(null);
        }
        break;

        case "recognizer.setWords": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          Boolean words = getRequiredArgumentFromMap(argsMap, "words", Boolean.class);

          try {
            recognizersMap.get(recognizerId).setWords(words);
          } catch (NullPointerException e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
            break;
          }

          result.success(null);
        }
        break;

        case "recognizer.setPartialWords": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          Boolean partialWords = getRequiredArgumentFromMap(argsMap, "partialWords", Boolean.class);

          try {
            recognizersMap.get(recognizerId).setPartialWords(partialWords);
          } catch (NullPointerException e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
            break;
          }

          result.success(null);
        }
        break;

        case "recognizer.acceptWaveForm": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          byte[] bytes = getArgumentFromMap(argsMap, "bytes", byte[].class);
          float[] floats = getArgumentFromMap(argsMap, "floats", float[].class);

          if (bytes == null && floats == null) {
            result.error("WRONG_ARGS", "Didn't find data. Pls, send data", null);
            break;
          }

          try {
            if (bytes == null) {
              result.success(
                  recognizersMap.get(recognizerId).acceptWaveForm(floats, floats.length));
            } else {
              result.success(recognizersMap.get(recognizerId).acceptWaveForm(bytes, bytes.length));
            }
          } catch (Exception e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
          }
        }
        break;

        case "recognizer.getResult": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          try {
            result.success(recognizersMap.get(recognizerId).getResult());
          } catch (Exception e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
          }
        }
        break;

        case "recognizer.getPartialResult": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          try {
            result.success(recognizersMap.get(recognizerId).getPartialResult());
          } catch (Exception e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
          }
        }
        break;

        case "recognizer.getFinalResult": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          try {
            result.success(recognizersMap.get(recognizerId).getFinalResult());
          } catch (Exception e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
          }
        }
        break;

        case "recognizer.setGrammar": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          String grammar = getRequiredArgumentFromMap(argsMap, "grammar", String.class);

          try {
            recognizersMap.get(recognizerId).setGrammar(grammar);
          } catch (Exception e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
          }

          result.success(null);
        }
        break;

        case "recognizer.reset": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          try {
            recognizersMap.get(recognizerId).reset();
          } catch (Exception e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
          }
          result.success(null);
        }
        break;

        case "recognizer.close": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          try {
            recognizersMap.get(recognizerId).close();
            recognizersMap.remove(recognizerId);
          } catch (Exception e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
          }
          result.success(null);
        }
        break;

        case "speechService.init": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);

          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          float sampleRate = getRequiredArgumentFromMap(argsMap, "sampleRate", Float.class);

          if (speechService == null) {
            try {
              speechService = new SpeechService(recognizersMap.get(recognizerId), sampleRate);
            } catch (IOException e) {
              result.error("INITIALIZE_FAIL", e.getMessage(), null);
              break;
            }
          } else {
            result.error("INITIALIZE_FAIL", "SpeechService instance already exist.", null);
            break;
          }
          result.success(null);
        }
        break;

        case "speechService.start": {
          result.success(speechService.startListening(recognitionListener));
        }
        break;

        case "speechService.stop": {
          result.success(speechService.stop());
        }
        break;

        case "speechService.setPause": {
          Boolean paused = castMethodCallArgs(call, Boolean.class);

          speechService.setPause(paused);
          result.success(null);
        }
        break;

        case "speechService.reset": {
          speechService.reset();
          result.success(null);
        }
        break;

        case "speechService.cancel": {
          result.success(speechService.cancel());
        }
        break;

        case "speechService.destroy": {
          speechService.shutdown();
          speechService = null;
          result.success(null);
        }
        break;

        default:
          result.notImplemented();
          break;
      }
    } catch (MissingRequiredArgument e) {
      result.error("MISSING_REQUIRED_ARGUMENT", "Couldn't find required argument", e);
    } catch (WrongArgumentTypeException e) {
      result.error("WRONG_TYPE", "Wrong argument type", e);
    }
  }

  public <T> T castMethodCallArgs(MethodCall call, Class<T> classType) throws WrongArgumentTypeException {
    if (classType.isInstance(call.arguments)) {
      return classType.cast(call.arguments);
    } else {
      throw new WrongArgumentTypeException(call.arguments.getClass(), classType,
          String.format("%s method", call.method));
    }
  }

  public <T> T getArgumentFromMap(Map<String, Object> map, String argumentName, Class<T> classType)
      throws WrongArgumentTypeException {
    Object argument = map.get(argumentName);
    if (argument == null) {
      return null;
    } else if (classType.isInstance(argument)) {
      return classType.cast(argument);
    } else {
      throw new WrongArgumentTypeException(argument.getClass(), classType,
          String.format("Argument %s", argumentName));
    }
  }

  public <T> T getRequiredArgumentFromMap(Map<String, Object> map, String argumentName,
      Class<T> classType)
      throws MissingRequiredArgument, WrongArgumentTypeException {
    T argument = getArgumentFromMap(map, argumentName, classType);
    if (argument == null) {
      throw new MissingRequiredArgument(argumentName);
    }

    return argument;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    recognitionListener.dispose();

    for (Recognizer recognizer : recognizersMap.values()) {
      recognizer.close();
    }
    recognizersMap.clear();

    for (Model model : modelsMap.values()) {
      model.close();
    }
    modelsMap.clear();
  }
}
