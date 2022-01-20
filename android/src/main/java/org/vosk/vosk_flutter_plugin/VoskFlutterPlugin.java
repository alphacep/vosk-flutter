package org.vosk.vosk_flutter_plugin;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import org.vosk.Model;
import org.vosk.android.RecognitionListener;
import org.vosk.android.StorageService;

import java.io.IOException;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** VoskFlutterPlugin */
public class VoskFlutterPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private SpeechRecognition speechRecognition;

  private Activity activity;

  private static final int PERMISSIONS_REQUEST_RECORD_AUDIO = 1;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "vosk_flutter_plugin");
    channel.setMethodCallHandler(this);
    speechRecognition = new SpeechRecognition(flutterPluginBinding);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {

      //LOAD AND INIT MODEL
      case "initModel":
        speechRecognition.initModel(call.arguments());
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
        break;



      default:
        result.notImplemented();
        break;
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    this.activity = binding.getActivity();
    check(activity);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {
    speechRecognition.dispose();
  }



  //Request for record audio permission
  public static boolean check(final Activity activity) {
    boolean permissionCheck = ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED;

    if (!permissionCheck) {
      ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.RECORD_AUDIO}, PERMISSIONS_REQUEST_RECORD_AUDIO);
      permissionCheck = ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED;
    }
    return permissionCheck;
  }
}
