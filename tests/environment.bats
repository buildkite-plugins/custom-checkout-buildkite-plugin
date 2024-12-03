#!/usr/bin/env bats

load 'helper-functions.bash'

setup() {
  setup_environment
}

teardown() {
  cleanup_environment
}

@test "Use default checkout path when none provided" {
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_CHECKOUT_PATH
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_INTERPOLATE_CHECKOUT_PATH

  source_plugin_hook "environment"

  [ "$BUILDKITE_BUILD_CHECKOUT_PATH" == "$DEFAULT_BUILDKITE_BUILD_CHECKOUT_PATH" ]
}

@test "Set custom checkout path" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_CHECKOUT_PATH="/custom/path"

  source_plugin_hook "environment"

  [ "$BUILDKITE_BUILD_CHECKOUT_PATH" == "/custom/path" ]
}

@test "Interpolate checkout path with environment variables" {
  export PROJECT_DIR="project"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_INTERPOLATE_CHECKOUT_PATH="/builds/${PROJECT_DIR}"

  source_plugin_hook "environment"

  [ "$BUILDKITE_BUILD_CHECKOUT_PATH" == "/builds/project" ]
}

@test "Handle empty checkout path" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_CHECKOUT_PATH=""

  source_plugin_hook "environment"

  [ "$BUILDKITE_BUILD_CHECKOUT_PATH" == "$DEFAULT_BUILDKITE_BUILD_CHECKOUT_PATH" ]
}

@test "Handle spaces in checkout path" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_CHECKOUT_PATH="/path with spaces"

  source_plugin_hook "environment"

  [ "$BUILDKITE_BUILD_CHECKOUT_PATH" == "/path with spaces" ]
}
