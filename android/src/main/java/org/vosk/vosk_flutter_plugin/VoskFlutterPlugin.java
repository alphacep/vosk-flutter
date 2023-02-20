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
    recognitionListener = new FlutterRecognitionListener(flutterPluginBinding);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {

/*      //LOAD AND INIT MODEL
      case "initModel":
        speechRecognition.initModel(call.arguments(), () -> channel.invokeMethod("init", null));
        result.success("success");
        break;

      //START
      case "start":
        try {
          speechRecognition.start();
          result.success("success");
        } catch (IOException e) {
          e.printStackTrace();
          result.error("ON START ERROR", e.getLocalizedMessage(), e);
        }
        break;

      //STOP
      case "stop":
        try {
          speechRecognition.stop();
          result.success("success");
        } catch (IOException e) {
          e.printStackTrace();
          result.error("ON STOP ERROR", e.getLocalizedMessage(), e);
        }
        break;*/

      case "model.create": {
        String modelPath = (String) call.arguments;
        if (modelPath == null) {
          result.error("WRONG_ARGS",
              "Please, send 1 string argument, contains model path", null);
        }

        new TaskRunner().executeAsync(
            () -> new Model(modelPath),
            (Model model) -> {
              modelsMap.put(modelPath, model);
              channel.invokeMethod("model.created", modelPath);
            },
            (Exception exception) -> {
              result.error("MODEL_ERROR", exception.getMessage(), null);
            });

        result.success(null);
      }
      break;

      case "recognizer.create": {
        HashMap<String, Object> argsMap = (HashMap<String, Object>) call.arguments;

        Integer sampleRate = getArgumentFromMap(result, argsMap, "sampleRate");
        String modelPath = getArgumentFromMap(result, argsMap, "modelPath");
        Model model = modelsMap.get(modelPath);
        if (model == null) {
          result.error("NO_MODEL",
              "Pls, create model or send correct path.", null);
        }
        String grammar = (String) argsMap.get("grammar");

        int recognizerId = recognizersMap.isEmpty() ? 1 : recognizersMap.lastKey() + 1;
        try {
          Recognizer recognizer = grammar == null ?
              new Recognizer(model, sampleRate) :
              new Recognizer(model, sampleRate, grammar);
          recognizersMap.put(recognizerId, recognizer);
        } catch (Exception e) {
          result.error("CREATION_ERROR", "Can't create recognizer.", null);
        }

        result.success(recognizerId);
      }
      break;

      case "recognizer.setMaxAlternatives": {
        HashMap<String, Object> argsMap = (HashMap<String, Object>) call.arguments;

        int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");
        int maxAlternatives = getArgumentFromMap(result, argsMap, "maxAlternatives");

        try {
          recognizersMap.get(recognizerId).setMaxAlternatives(maxAlternatives);
        } catch (NullPointerException e) {
          result.error("NO_RECOGNIZER", "There is no recognizer with this id.", null);
        }

        result.success(null);
      }
      break;

      case "recognizer.setWords": {
        HashMap<String, Object> argsMap = (HashMap<String, Object>) call.arguments;

        int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");
        boolean words = getArgumentFromMap(result, argsMap, "words");

        try {
          recognizersMap.get(recognizerId).setWords(words);
        } catch (NullPointerException e) {
          result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
        }

        result.success(null);
      }
      break;

      case "recognizer.setPartialWords": {
        HashMap<String, Object> argsMap = (HashMap<String, Object>) call.arguments;

        int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");
        boolean partialWords = getArgumentFromMap(result, argsMap, "partialWords");

        try {
          recognizersMap.get(recognizerId).setPartialWords(partialWords);
        } catch (NullPointerException e) {
          result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
        }

        result.success(null);
      }
      break;

      case "recognizer.acceptWaveForm": {
        HashMap<String, Object> argsMap = (HashMap<String, Object>) call.arguments;

        int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");
        byte[] bytes = (byte[]) argsMap.get("bytes");
        float[] floats = (float[]) argsMap.get("floats");

        if (bytes == null && floats == null) {
          result.error("WRONG_ARGS", "Didn't find data. Pls, send data", null);
        }

        try {
          if (bytes == null) {
            result.success(recognizersMap.get(recognizerId).acceptWaveForm(floats, floats.length));
          } else {
            result.success(recognizersMap.get(recognizerId).acceptWaveForm(bytes, bytes.length));
          }
        } catch (Exception e) {
          result.error("WRONG_RECOGNIZER_ID", "There is no recognizer with this id.", null);
        }
      }
      break;

      case "recognizer.getResult": {
        HashMap<String, Object> argsMap = (HashMap<String, Object>) call.arguments;

        int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");

        try {
          result.success(recognizersMap.get(recognizerId).getResult());
        } catch (Exception e) {
          result.error("RESULT_ERROR", "Error while getting result from recognizer.",
              null);
        }
      }
      break;

      case "recognizer.getPartialResult": {
        HashMap<String, Object> argsMap = (HashMap<String, Object>) call.arguments;

        int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");

        try {
          result.success(recognizersMap.get(recognizerId).getPartialResult());
        } catch (Exception e) {
          result.error("RESULT_ERROR",
              "Error while getting partial result from recognizer.",
              null);
        }
      }
      break;

      case "recognizer.getFinalResult": {
        HashMap<String, Object> argsMap = (HashMap<String, Object>) call.arguments;

        int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");

        try {
          result.success(recognizersMap.get(recognizerId).getFinalResult());
        } catch (Exception e) {
          result.error("RESULT_ERROR",
              "Error while getting final result from recognizer.",
              null);
        }
      }
      break;

      case "recognizer.setGrammar": {
        HashMap<String, Object> argsMap = (HashMap<String, Object>) call.arguments;

        int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");
        String grammar = getArgumentFromMap(result, argsMap, "grammar");

        try {
          recognizersMap.get(recognizerId).setGrammar(grammar);
        } catch (Exception e) {
          result.error("GRAMMAR_SET_ERROR", "Can't set grammar.", null);
        }

        result.success(null);
      }
      break;

      case "recognizer.reset": {
        HashMap<String, Object> argsMap = (HashMap<String, Object>) call.arguments;

        int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");

        try {
          recognizersMap.get(recognizerId).reset();
        } catch (Exception e) {
          result.error("RESET_ERROR", "Can't reset.", null);
        }
        result.success(null);
      }
      break;

      case "recognizer.close": {
        HashMap<String, Object> argsMap = (HashMap<String, Object>) call.arguments;

        int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");

        try {
          recognizersMap.get(recognizerId).close();
        } catch (Exception e) {
          result.error("CLOSE_ERROR", "Can't close.", null);
        }
        result.success(null);
      }
      break;

      case "speechService.init": {
        HashMap<String, Object> argsMap = (HashMap<String, Object>) call.arguments;

        int recognizerId = getArgumentFromMap(result, argsMap, "recognizerId");
        //float sampleRate = getParamFromMap(result, argsMap, "sampleRate");

        if (speechService == null) {
          try {
            speechService = new SpeechService(recognizersMap.get(recognizerId), 16000.00f);
          } catch (IOException e) {
            result.error("INITIALIZE_FAIL", e.getMessage(), null);
          } catch (Exception e) {
            result.error("INITIALIZE_FAIL", "Can't initialize speech service.", null);
          }
        } else {
          result.error("INITIALIZE_FAIL", "SpeechService instance already exist.", null);
        }
        result.success(null);
      }
      break;

      case "speechService.start": {
        if (speechService == null) {
          result.error("NO_INSTANCE", "Create speechService first.", null);
        }
        try {
          result.success(speechService.startListening(recognitionListener));
        } catch (Exception e) {
          result.error("LISTEN_ERROR", "Couldn't start listen.", null);
        }
      }
      break;

      case "speechService.stop": {
        try {
          result.success(speechService.stop());
        } catch (Exception e) {
          result.error("STOP_ERROR", "Error while stopping speechService.", null);
        }
      }
      break;

      case "speechService.setPause": {
        boolean isPause = (boolean) call.arguments;
        try {
          speechService.setPause(isPause);
        } catch (Exception e) {
          result.error("PAUSE_ERROR", "An error occurred while trying to pause", null);
        }
        result.success(null);
      }
      break;

      case "speechService.reset": {
        try {
          speechService.reset();
        } catch (Exception e) {
          result.error("RESET_ERROR", "An error occured while trying to reset.", null);
        }
        result.success(null);
      }
      break;

      case "speechService.cancel": {
        try {
          result.success(speechService.cancel());
        } catch (Exception e) {
          result.error("CANCEL_ERROR", "Error while cancelling.", null);
        }
      }
      break;

      case "speechService.destroy": {
        try {
          speechService.shutdown();
        } catch (Exception e) {
          result.error("SHUT_DOWN_ERROR", "An error occured while trying to Shut down.", null);
        }
        result.success(null);
      }
      break;

      default:
        result.notImplemented();
        break;
    }

  }

  public <T> T getArgumentFromMap(Result result, Map<String, Object> map, String argumentName) {
    Object argument = map.get(argumentName);
    if (argument == null) {
      result.error("WRONG_ARGUMENTS", String.format("Pls send argument \"%s\"", argumentName),
          null);
    }
    return (T) argument;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    recognitionListener.dispose();
  }
}
