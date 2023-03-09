package org.vosk.vosk_flutter;

import android.os.Handler;
import android.os.Looper;

import androidx.core.util.Consumer;

import java.util.concurrent.Callable;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

public class TaskRunner {

  private final Handler handler = new Handler(Looper.getMainLooper());
  private final Executor executor = Executors.newSingleThreadExecutor();

  public <T> void executeAsync(Callable<T> callable, Consumer<T> callback,
      Consumer<Exception> onError) {
    executor.execute(() -> {
      final T result;
      try {
        result = callable.call();
      } catch (Exception e) {
        handler.post(() -> onError.accept(e));
        return;
      }
      handler.post(() -> callback.accept(result));
    });
  }
};