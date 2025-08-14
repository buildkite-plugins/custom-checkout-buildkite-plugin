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

@test "Clone from mirror_url if provided" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_MIRROR_URL="https://github.com/example/mirror-repo.git"

  # Simulate a successful mirror clone by mocking git
  git() {
    if [[ "$1" == "clone" && "$2" == "https://github.com/example/mirror-repo.git" ]]; then
      mkdir -p .git
      return 0
    elif [[ "$1" == "clone" && "$2" == "https://github.com/example/repo.git" ]]; then
      return 1
    else
      command git "$@"
    fi
  }

  run run_plugin_hook "checkout"

  [ "$status" -eq 0 ]
  [ -d "$BUILDKITE_BUILD_CHECKOUT_PATH/.git" ]
}

@test "Falls back to original URL if mirror clone fails" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_MIRROR_URL="https://github.com/example/mirror-repo.git"

  # Simulate mirror clone failure, original clone success
  git() {
    if [[ "$1" == "clone" && "$2" == "https://github.com/example/mirror-repo.git" ]]; then
      return 1
    elif [[ "$1" == "clone" && "$2" == "https://github.com/example/repo.git" ]]; then
      mkdir -p .git
      return 0
    else
      command git "$@"
    fi
  }

  run run_plugin_hook "checkout"

  [ "$status" -eq 0 ]
  [ -d "$BUILDKITE_BUILD_CHECKOUT_PATH/.git" ]
}

@test "Uses only original URL if mirror_url is not provided" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_MIRROR_URL

  # Simulate original clone success
  git() {
    if [[ "$1" == "clone" && "$2" == "https://github.com/example/repo.git" ]]; then
      mkdir -p .git
      return 0
    else
      command git "$@"
    fi
  }

  run run_plugin_hook "checkout"

  [ "$status" -eq 0 ]
  [ -d "$BUILDKITE_BUILD_CHECKOUT_PATH/.git" ]
}

@test "Checks out correct ref when using mirror_url" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_MIRROR_URL="https://github.com/example/mirror-repo.git"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_REF="feature-branch"

  # Simulate mirror clone success and checkout
  git() {
    if [[ "$1" == "clone" && "$2" == "https://github.com/example/mirror-repo.git" ]]; then
      mkdir -p .git
      return 0
    elif [[ "$1" == "checkout" && "$2" == "feature-branch" ]]; then
      return 0
    else
      command git "$@"
    fi
  }

  run run_plugin_hook "checkout"

  [ "$status" -eq 0 ]
  [ -d "$BUILDKITE_BUILD_CHECKOUT_PATH/.git" ]
}

@test "Clone multiple repositories into separate directories" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo1.git"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_1_URL="https://github.com/example/repo2.git"

  git() {
    if [[ "$1" == "clone" ]]; then
      local repo_url="$2"
      mkdir -p .git
      echo "Cloned $repo_url into $(pwd)" > .git/clone_info
      return 0
    else
      command git "$@"
    fi
  }

  run run_plugin_hook "checkout"

  [ "$status" -eq 0 ]
  [ -d "$BUILDKITE_BUILD_CHECKOUT_PATH/repo1/.git" ]
  [ -d "$BUILDKITE_BUILD_CHECKOUT_PATH/repo2/.git" ]
}

@test "Clone repository with custom checkout path" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_CHECKOUT_PATH="custom-dir"

  git() {
    if [[ "$1" == "clone" ]]; then
      mkdir -p .git
      return 0
    else
      command git "$@"
    fi
  }

  run run_plugin_hook "checkout"

  [ "$status" -eq 0 ]
  [ -d "$BUILDKITE_BUILD_CHECKOUT_PATH/custom-dir/.git" ]
}