package org.vosk.vosk_flutter;

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
import org.vosk.vosk_flutter.exceptions.MissingRequiredArgument;
import org.vosk.vosk_flutter.exceptions.RecognizerNotFound;
import org.vosk.vosk_flutter.exceptions.SpeechServiceNotFound;
import org.vosk.vosk_flutter.exceptions.WrongArgumentTypeException;
import org.vosk.SpeakerModel;

/**
 * VoskFlutterPlugin
 */
public class VoskFlutterPlugin implements FlutterPlugin, MethodCallHandler {

  private static final Class<HashMap<String, Object>> argsMapClass = (Class<HashMap<String, Object>>) new HashMap<String, Object>().getClass();

  private final HashMap<String, Model> modelsMap = new HashMap<>();
  private final HashMap<String, SpeakerModel> speakerModelsMap = new HashMap<>();
  private final TreeMap<Integer, Recognizer> recognizersMap = new TreeMap<>();

  private MethodChannel channel;
  private SpeechService speechService;
  private FlutterRecognitionListener recognitionListener;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "vosk_flutter");
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

          new TaskRunner().executeAsync(() -> new Model(modelPath), (model) -> {
            modelsMap.put(modelPath, model);
            channel.invokeMethod("model.created", modelPath);
          }, (exception) -> channel.invokeMethod("model.error", new HashMap<String, Object>() {{
            put("modelPath", modelPath);
            put("error", exception.getMessage());
          }}));

          result.success(null);
        }
        break;

        case "speakerModel.create": {
          String modelPath = castMethodCallArgs(call, String.class);
          if (modelPath == null) {
            result.error("WRONG_ARGS", "Please, send 1 string argument, contains speaker model path", null);
            break;
          }

          new TaskRunner().executeAsync(() -> new SpeakerModel(modelPath), (speakerModel) -> {
            speakerModelsMap.put(modelPath, speakerModel);
            channel.invokeMethod("speakerModel.created", modelPath);
          }, (exception) -> channel.invokeMethod("speakerModel.error", new HashMap<String, Object>() {{
            put("modelPath", modelPath);
            put("error", exception.getMessage());
          }}));

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

        case "recognizer.setSpeakerModel": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          String speakerModelPath = getRequiredArgumentFromMap(argsMap, "speakerModelPath", String.class);

          SpeakerModel speakerModel = speakerModelsMap.get(speakerModelPath);
          if (speakerModel == null) {
            result.error("NO_SPEAKER_MODEL", "Couldn't find speaker model with this path. Pls, create speaker model or send correct path.", null);
            break;
          }

          getRecognizerById(recognizerId).setSpeakerModel(speakerModel);
          result.success(null);
        }
        break;


        case "recognizer.setMaxAlternatives": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          Integer maxAlternatives = getRequiredArgumentFromMap(argsMap, "maxAlternatives",
              Integer.class);

          getRecognizerById(recognizerId).setMaxAlternatives(maxAlternatives);
          result.success(null);
        }
        break;

        case "recognizer.setWords": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          Boolean words = getRequiredArgumentFromMap(argsMap, "words", Boolean.class);

          getRecognizerById(recognizerId).setWords(words);
          result.success(null);
        }
        break;

        case "recognizer.setPartialWords": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          Boolean partialWords = getRequiredArgumentFromMap(argsMap, "partialWords", Boolean.class);

          getRecognizerById(recognizerId).setPartialWords(partialWords);
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

          Recognizer recognizer = getRecognizerById(recognizerId);
          if (bytes == null) {
            result.success(recognizer.acceptWaveForm(floats, floats.length));
          } else {
            result.success(recognizer.acceptWaveForm(bytes, bytes.length));
          }

        }
        break;

        case "recognizer.getResult": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          result.success(getRecognizerById(recognizerId).getResult());
        }
        break;

        case "recognizer.getPartialResult": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          result.success(getRecognizerById(recognizerId).getPartialResult());
        }
        break;

        case "recognizer.getFinalResult": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          result.success(getRecognizerById(recognizerId).getFinalResult());
        }
        break;

        case "recognizer.setGrammar": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          String grammar = getRequiredArgumentFromMap(argsMap, "grammar", String.class);

          getRecognizerById(recognizerId).setGrammar(grammar);
          result.success(null);
        }
        break;

        case "recognizer.reset": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          getRecognizerById(recognizerId).reset();
          result.success(null);
        }
        break;

        case "recognizer.close": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          getRecognizerById(recognizerId).close();
          recognizersMap.remove(recognizerId);
          result.success(null);
        }
        break;

        case "speechService.init": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          Integer sampleRate = getRequiredArgumentFromMap(argsMap, "sampleRate", Integer.class);

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
          if (speechService == null) {
            throw new SpeechServiceNotFound();
          }
          result.success(speechService.startListening(recognitionListener));
        }
        break;

        case "speechService.stop": {
          if (speechService == null) {
            throw new SpeechServiceNotFound();
          }
          result.success(speechService.stop());
        }
        break;

        case "speechService.setPause": {
          if (speechService == null) {
            throw new SpeechServiceNotFound();
          }

          Boolean paused = castMethodCallArgs(call, Boolean.class);

          speechService.setPause(paused);
          result.success(null);
        }
        break;

        case "speechService.reset": {
          if (speechService == null) {
            throw new SpeechServiceNotFound();
          }
          speechService.reset();
          result.success(null);
        }
        break;

        case "speechService.cancel": {
          if (speechService == null) {
            throw new SpeechServiceNotFound();
          }
          result.success(speechService.cancel());
        }
        break;

        case "speechService.destroy": {
          if (speechService == null) {
            throw new SpeechServiceNotFound();
          }
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
    } catch (RecognizerNotFound e) {
      result.error("NO_RECOGNIZER", "There is no recognizer with this id.", e);
    } catch (SpeechServiceNotFound e) {
      result.error("NO_SPEECH_SERVICE", "Speech service not created.", e);
    }
  }

  public <T> T castMethodCallArgs(MethodCall call, Class<T> classType)
      throws WrongArgumentTypeException {
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
      Class<T> classType) throws MissingRequiredArgument, WrongArgumentTypeException {
    T argument = getArgumentFromMap(map, argumentName, classType);
    if (argument == null) {
      throw new MissingRequiredArgument(argumentName);
    }

    return argument;
  }

  Recognizer getRecognizerById(Integer recognizerId) throws RecognizerNotFound {
    Recognizer recognizer = recognizersMap.get(recognizerId);
    if (recognizer == null) {
      throw new RecognizerNotFound(recognizerId);
    }
    return recognizer;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    recognitionListener.dispose();

    if (speechService != null) {
      speechService.shutdown();
      speechService = null;
    }

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
