# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "vosk_flutter")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "vosk_flutter_plugin")

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED "vosk_flutter_plugin.cpp")

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(vosk_flutter_bundled_libraries
  "${CMAKE_CURRENT_SOURCE_DIR}/libs/libvosk.dll"
  "${CMAKE_CURRENT_SOURCE_DIR}/libs/libgcc_s_seh-1.dll"
  "${CMAKE_CURRENT_SOURCE_DIR}/libs/libstdc++-6.dll"
  "${CMAKE_CURRENT_SOURCE_DIR}/libs/libwinpthread-1.dll"
  PARENT_SCOPE
)

#message ("FLUTTER_ROOT is $ENV{FLUTTER_ROOT}")

# Install VOSK binaries.
execute_process(COMMAND "$ENV{FLUTTER_ROOT}\\bin\\flutter.bat" "pub" "run" "vosk_flutter" "install" "-t" "windows"
        OUTPUT_VARIABLE output
        RESULT_VARIABLE result
        COMMAND_ERROR_IS_FATAL ANY
        )
message(STATUS "cmd output: ${output}")
message(STATUS "cmd result: ${result}")
