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

  private MethodChannel channel;
  private FlutterRecognitionListener recognitionListener;
  private SpeechService speechService;

  private static final HashMap<String, Model> modelsMap = new HashMap<>();
  private static final TreeMap<Integer, Recognizer> recognizersMap = new TreeMap<>();

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
          String modelPath = castToRequiredType(String.class, call.arguments);
          if (modelPath == null) {
            result.error("WRONG_ARGS",
                "Please, send 1 string argument, contains model path", null);
            break;
          }

          new TaskRunner().executeAsync(
              () -> new Model(modelPath),
              (Model model) -> {
                modelsMap.put(modelPath, model);
                channel.invokeMethod("model.created", modelPath);
              },
              (Exception exception) -> {
                result.error("MODEL_ERROR", exception.getMessage(), exception);
              });

          result.success(null);
        }
        break;

        case "recognizer.create": {
          Map<String, Object> argsMap = castToRequiredType(HashMap.class, call.arguments);
          Integer sampleRate = getArgumentFromMap(result, argsMap, "sampleRate");
          String modelPath = getArgumentFromMap(result, argsMap, "modelPath");
          Model model = modelsMap.get(modelPath);
          if (model == null) {
            result.error("NO_MODEL",
                "Couldn't find model with this path. Pls, create model or send correct path.",
                null);
            break;
          }

          int recognizerId = recognizersMap.isEmpty() ? 1 : recognizersMap.lastKey() + 1;
          try {
            Recognizer recognizer = argsMap.get("grammar") == null ?
                new Recognizer(model, sampleRate) :
                new Recognizer(model, sampleRate,
                    castToRequiredType(String.class, argsMap.get("grammar")));
            recognizersMap.put(recognizerId, recognizer);
          } catch (IOException e) {
            result.error("CREATION_ERROR", "Can't create recognizer.", e);
            break;
          }

          result.success(recognizerId);
        }
        break;

        case "recognizer.setMaxAlternatives": {
          Map<String, Object> argsMap = castToRequiredType(HashMap.class, call.arguments);

          int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");
          int maxAlternatives = getArgumentFromMap(result, argsMap, "maxAlternatives");

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
          Map<String, Object> argsMap = castToRequiredType(HashMap.class, call.arguments);

          int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");
          boolean words = getArgumentFromMap(result, argsMap, "words");

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
          Map<String, Object> argsMap = castToRequiredType(HashMap.class, call.arguments);

          int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");
          boolean partialWords = getArgumentFromMap(result, argsMap, "partialWords");

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
          Map<String, Object> argsMap = castToRequiredType(HashMap.class, call.arguments);

          int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");
          byte[] bytes = (byte[]) argsMap.get("bytes");
          float[] floats = (float[]) argsMap.get("floats");

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
          Map<String, Object> argsMap = castToRequiredType(HashMap.class, call.arguments);

          int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");

          try {
            result.success(recognizersMap.get(recognizerId).getResult());
          } catch (Exception e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
          }
        }
        break;

        case "recognizer.getPartialResult": {
          Map<String, Object> argsMap = castToRequiredType(HashMap.class, call.arguments);

          int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");

          try {
            result.success(recognizersMap.get(recognizerId).getPartialResult());
          } catch (Exception e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
          }
        }
        break;

        case "recognizer.getFinalResult": {
          Map<String, Object> argsMap = castToRequiredType(HashMap.class, call.arguments);

          int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");

          try {
            result.success(recognizersMap.get(recognizerId).getFinalResult());
          } catch (Exception e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
          }
        }
        break;

        case "recognizer.setGrammar": {
          Map<String, Object> argsMap = castToRequiredType(HashMap.class, call.arguments);

          int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");
          String grammar = getArgumentFromMap(result, argsMap, "grammar");

          try {
            recognizersMap.get(recognizerId).setGrammar(grammar);
          } catch (Exception e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
          }

          result.success(null);
        }
        break;

        case "recognizer.reset": {
          Map<String, Object> argsMap = castToRequiredType(HashMap.class, call.arguments);

          int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");

          try {
            recognizersMap.get(recognizerId).reset();
          } catch (Exception e) {
            result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
          }
          result.success(null);
        }
        break;

        case "recognizer.close": {
          Map<String, Object> argsMap = castToRequiredType(HashMap.class, call.arguments);

          int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");

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
          Map<String, Object> argsMap = castToRequiredType(HashMap.class, call.arguments);

          int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");
          float sampleRate = getArgumentFromMap(result, argsMap, "sampleRate");

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
          boolean isPause = castToRequiredType(boolean.class, call.arguments);

          speechService.setPause(isPause);
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
    } catch (ArgumentNotFoundException e) {
      result.error("WRONG_ARGUMENTS", "Couldn't find expected argument.", e);
    } catch (WrongTypeException e) {
      result.error("WRONG_TYPE", "Wrong argument type.", e);
    }

  }

  public <T> T castToRequiredType(Class<T> classType, Object arguments) throws WrongTypeException {
    if (classType.isInstance(arguments)) {
      return classType.cast(arguments);
    } else {
      throw new WrongTypeException(arguments.getClass().getName(), classType.getName());
    }
  }

  public <T> T getArgumentFromMap(Result result, Map<String, Object> map, String argumentName)
      throws ArgumentNotFoundException {
    Object argument = map.get(argumentName);
    if (argument == null) {
      throw new ArgumentNotFoundException(argumentName);
    }
    return (T) argument;
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
