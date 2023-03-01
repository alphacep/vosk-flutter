package org.vosk.vosk_flutter_plugin;

import androidx.test.rule.ActivityTestRule;
import org.vosk.vosk_flutter_plugin_example.MainActivity;
import org.junit.Rule;
import org.junit.runner.RunWith;

@RunWith(FlutterRunner.class)
public class MainActivityTest {

  @Rule
  public ActivityTestRule<MainActivity> rule = new ActivityTestRule<>(MainActivity.class);
}
