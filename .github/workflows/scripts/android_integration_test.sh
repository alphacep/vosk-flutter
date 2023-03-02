#!/bin/bash

set -e

flutter drive --driver=test_driver/test_driver.dart --target=integration_test/vosk_flutter_plugin_test.dart
