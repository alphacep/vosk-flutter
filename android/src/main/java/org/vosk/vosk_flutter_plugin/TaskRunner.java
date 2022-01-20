package org.vosk.vosk_flutter_plugin;

import android.os.Handler;
import android.os.Looper;

import java.util.concurrent.Callable;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

public class TaskRunner {
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Executor executor = Executors.newSingleThreadExecutor();

    public interface Callback<R> {
        void onComplete(R result);
    }

    public <R> void executeAsync(Callable<R> callable, Callback<R> callback) {
        executor.execute(new RunnableTask<R>(handler, callable, callback));
    }

    public static class RunnableTask<R> implements Runnable {
        private final Handler handler;
        private final Callable<R> callable;
        private final Callback<R> callback;

        public RunnableTask(Handler handler, Callable<R> callable, Callback<R> callback) {
            this.handler = handler;
            this.callable = callable;
            this.callback = callback;
        }

        @Override
        public void run() {
            try {
                final R result = callable.call();
                handler.post(new RunnableTaskForHandler<>(result, callback));
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }
    }

    public static class RunnableTaskForHandler<R> implements Runnable {
        private Callback<R> callback;
        private R result;

        public RunnableTaskForHandler(R result, Callback<R> callback) {
            this.result = result;
            this.callback = callback;
        }

        @Override
        public void run() {
            callback.onComplete(result);
        }
    }
};