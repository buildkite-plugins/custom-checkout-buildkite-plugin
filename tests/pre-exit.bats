#!/usr/bin/env bats

load 'helper-functions.bash'

setup() {
  setup_environment
}

teardown() {
  cleanup_environment
}

@test "Delete checkout directory when configured" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_DELETE_CHECKOUT="true"
  
  # Create a test file to verify deletion
  touch "$BUILDKITE_BUILD_CHECKOUT_PATH/test-file"
  
  run run_plugin_hook "pre-exit"

  [ "$status" -eq 0 ]
  [ ! -d "$BUILDKITE_BUILD_CHECKOUT_PATH" ]
}

@test "Do not delete checkout directory when not configured" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_DELETE_CHECKOUT="false"
  
  # Create a test file to verify it remains
  touch "$BUILDKITE_BUILD_CHECKOUT_PATH/test-file"
  
  run run_plugin_hook "pre-exit"

  [ "$status" -eq 0 ]
  [ -d "$BUILDKITE_BUILD_CHECKOUT_PATH" ]
  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/test-file" ]
}

@test "Handle non-existent checkout directory" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_DELETE_CHECKOUT="true"
  rm -rf "$BUILDKITE_BUILD_CHECKOUT_PATH"

  run run_plugin_hook "pre-exit"

  [ "$status" -eq 0 ]
}