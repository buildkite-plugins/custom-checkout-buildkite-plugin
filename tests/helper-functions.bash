#!/usr/bin/env bash

# Set default checkout path for tests
DEFAULT_BUILDKITE_BUILD_CHECKOUT_PATH="/tmp/buildkite-test-checkout"

setup_environment() {
  # Create a clean test environment
  export BUILDKITE_BUILD_CHECKOUT_PATH="$DEFAULT_BUILDKITE_BUILD_CHECKOUT_PATH"
  export BUILDKITE_COMMIT="HEAD"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_CHECKOUT_PATH=""
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_INTERPOLATE_CHECKOUT_PATH=""
  
  # Ensure the plugin directory is set correctly
  export BUILDKITE_PLUGIN_DIR="${BUILDKITE_PLUGIN_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
  
  # Create checkout directory
  mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH"
}

cleanup_environment() {
  # Clean up test environment
  if [[ -n "${BUILDKITE_BUILD_CHECKOUT_PATH:-}" ]] && [[ -d "$BUILDKITE_BUILD_CHECKOUT_PATH" ]]; then
    rm -rf "$BUILDKITE_BUILD_CHECKOUT_PATH"
  fi
  
  # Unset all plugin variables
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_CHECKOUT_PATH
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_INTERPOLATE_CHECKOUT_PATH
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_DELETE_CHECKOUT
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_REF
}

run_plugin_hook() {
  local hook_name="$1"
  shift
  
  local hook_path="$BUILDKITE_PLUGIN_DIR/hooks/$hook_name"
  if [[ ! -f "$hook_path" ]]; then
    echo "Hook not found: $hook_path"
    return 1
  fi
  
  chmod +x "$hook_path"
  "$hook_path" "$@"
}

source_plugin_hook() {
  local hook_name="$1"
  shift
  
  local hook_path="$BUILDKITE_PLUGIN_DIR/hooks/$hook_name"
  if [[ ! -f "$hook_path" ]]; then
    echo "Hook not found: $hook_path"
    return 1
  fi
  
  source "$hook_path" "$@"
}