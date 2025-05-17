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

@test "Clone with additional flags" {
  # Set up a minimal local git repo to clone
  export TEST_REPO_DIR="$BATS_TMPDIR/test-origin"
  mkdir -p "$TEST_REPO_DIR"
  git -C "$TEST_REPO_DIR" init --bare

  # Configure the plugin with clone flags
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="file://$TEST_REPO_DIR"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_CLONE_FLAGS_0="--depth=1"
  export BUILDKITE_BUILD_CHECKOUT_PATH="$BATS_TMPDIR/checkout"
  mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH"

  # Mock git to capture clone arguments
  export MOCK_GIT_ARGS_FILE="$BATS_TMPDIR/git-args"
  function git() {
    if [[ "$1" == "clone" ]]; then
      echo "MOCK: git clone called with: $@" > "$MOCK_GIT_ARGS_FILE"
      local target_dir="${@: -1}"
      mkdir -p "$target_dir/.git"
      return 0
    else
      command git "$@"
    fi
  }
  export -f git

  run run_plugin_hook "checkout"

  # Verify correct behavior
  [ "$status" -eq 0 ]
  echo "$output" | grep 'Cloning with flags: "--depth=1"'
  cat "$MOCK_GIT_ARGS_FILE" | grep -- "--depth=1"
}