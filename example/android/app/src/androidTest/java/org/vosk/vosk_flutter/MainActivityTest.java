package org.vosk.vosk_flutter;

import androidx.test.rule.ActivityTestRule;
import org.vosk.vosk_flutter_example.MainActivity;
import org.junit.Rule;
import org.junit.runner.RunWith;

@RunWith(FlutterRunner.class)
public class MainActivityTest {

  @Rule
  public ActivityTestRule<MainActivity> rule = new ActivityTestRule<>(MainActivity.class);
}
