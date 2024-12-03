#!/usr/bin/env bats

load 'helper-functions.bash'

setup() {
  setup_environment
}

teardown() {
  cleanup_environment
}

@test "Skip checkout when configured" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="true"

  run run_plugin_hook "checkout"

  [ "$status" -eq 0 ]
  [ ! -d "$BUILDKITE_BUILD_CHECKOUT_PATH/repo" ]
}

@test "Fail when repository URL is missing" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 1 ]
}