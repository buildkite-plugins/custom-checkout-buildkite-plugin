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

@test "Checkout with fetch enabled" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_FETCH="true"
  export BUILDKITE_COMMIT="abc123"

  run run_plugin_hook "checkout"

  [ "$status" -eq 0 ]
  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called" ]
  grep -q "abc123" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called"
}

@test "Checkout with fetch flags" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_FETCH="true"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_FETCH_FLAGS_0="--depth=1"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_FETCH_FLAGS_1="--prune"
  export BUILDKITE_COMMIT="abc123"

  run run_plugin_hook "checkout"

  [ "$status" -eq 0 ]
  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called" ]
  grep -q -- "--depth=1" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called"
  grep -q -- "--prune" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called"
}

@test "Reuses existing repository on persistent agent instead of re-cloning" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"

  # Simulate a pre-existing repository from a previous build (persistent agent scenario)
  mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/.git"

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 0 ]

  # Verify fetch --all --prune was called (update path), not a fresh clone
  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called" ]
  grep -q -- "--all" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called"
  grep -q -- "--prune" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called"
}

@test "Checks out correct ref on persistent agent after fetching updates" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_REF="main"

  # Simulate a pre-existing repository
  mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/.git"

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 0 ]

  # fetch --all --prune was called (update path taken)
  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called" ]
  grep -q -- "--all" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called"

  # checkout_ref still ran and checked out the specified ref
  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called" ]
  grep -q "main" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called"
}

@test "Updates remote URL when reusing existing repository on persistent agent" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/new-location/repo.git"

  # Simulate a pre-existing repository (may have had a different remote URL)
  mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/.git"

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 0 ]

  # remote set-url was called with the current (possibly new) URL
  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/remote_seturl_called" ]
  grep -q "https://github.com/example/new-location/repo.git" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/remote_seturl_called"
}

@test "Resets working tree to clean state before checkout" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 0 ]

  # git reset --hard HEAD was called to discard any leftover changes
  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/reset_called" ]
  grep -q -- "--hard" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/reset_called"

  # git clean -ffdx was called to remove untracked files
  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/clean_called" ]
  grep -q -- "-ffdx" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/clean_called"
}

@test "Reuses all existing repositories on persistent agent with multiple repos" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo1.git"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_1_URL="https://github.com/example/repo2.git"

  # Both repos already exist from a previous build
  mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/repo1/.git"
  mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/repo2/.git"

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 0 ]

  # Both repos were updated via fetch, not re-cloned
  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/repo1/.git/fetch_called" ]
  grep -q -- "--all" "$BUILDKITE_BUILD_CHECKOUT_PATH/repo1/.git/fetch_called"

  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/repo2/.git/fetch_called" ]
  grep -q -- "--all" "$BUILDKITE_BUILD_CHECKOUT_PATH/repo2/.git/fetch_called"
}

@test "Fetches merge ref and checks out FETCH_HEAD when merge refspec is enabled" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PULL_REQUEST_USING_MERGE_REFSPEC="true"
  export BUILDKITE_PULL_REQUEST="42"
  export BUILDKITE_REPO="https://github.com/example/repo.git"

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 0 ]

  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called" ]
  grep -q "refs/pull/42/merge" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called"

  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called" ]
  grep -q "FETCH_HEAD" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called"
}

@test "Merge refspec is ignored when BUILDKITE_PULL_REQUEST is false" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PULL_REQUEST_USING_MERGE_REFSPEC="true"
  export BUILDKITE_PULL_REQUEST="false"
  export BUILDKITE_REPO="https://github.com/example/repo.git"

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 0 ]

  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called" ]
  ! grep -q "FETCH_HEAD" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called"
}

@test "Merge refspec is ignored when flag is not set" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PULL_REQUEST="42"
  export BUILDKITE_REPO="https://github.com/example/repo.git"
  unset BUILDKITE_PULL_REQUEST_USING_MERGE_REFSPEC

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 0 ]

  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called" ]
  ! grep -q "FETCH_HEAD" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called"
}

@test "Explicit ref takes precedence over merge refspec" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_REF="main"
  export BUILDKITE_PULL_REQUEST_USING_MERGE_REFSPEC="true"
  export BUILDKITE_PULL_REQUEST="42"
  export BUILDKITE_REPO="https://github.com/example/repo.git"

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 0 ]

  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called" ]
  grep -q "main" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called"
  ! grep -q "FETCH_HEAD" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called"
}

@test "Merge refspec only applies to the repo matching BUILDKITE_REPO" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo1.git"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_1_URL="https://github.com/example/repo2.git"
  export BUILDKITE_PULL_REQUEST_USING_MERGE_REFSPEC="true"
  export BUILDKITE_PULL_REQUEST="42"
  export BUILDKITE_REPO="https://github.com/example/repo1.git"

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 0 ]

  # repo1 should use merge refspec
  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/repo1/.git/fetch_called" ]
  grep -q "refs/pull/42/merge" "$BUILDKITE_BUILD_CHECKOUT_PATH/repo1/.git/fetch_called"
  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/repo1/.git/checkout_called" ]
  grep -q "FETCH_HEAD" "$BUILDKITE_BUILD_CHECKOUT_PATH/repo1/.git/checkout_called"

  # repo2 should not use merge refspec
  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/repo2/.git/checkout_called" ]
  ! grep -q "FETCH_HEAD" "$BUILDKITE_BUILD_CHECKOUT_PATH/repo2/.git/checkout_called"
}

@test "Merge refspec works on persistent agent with existing repo" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PULL_REQUEST_USING_MERGE_REFSPEC="true"
  export BUILDKITE_PULL_REQUEST="42"
  export BUILDKITE_REPO="https://github.com/example/repo.git"

  # Simulate pre-existing repository (persistent agent)
  mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/.git"

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 0 ]

  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called" ]
  grep -q -- "--all" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called"
  grep -q "refs/pull/42/merge" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called"

  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called" ]
  grep -q "FETCH_HEAD" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called"
}

@test "Merge refspec works with SSH BUILDKITE_REPO matching HTTPS plugin URL" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PULL_REQUEST_USING_MERGE_REFSPEC="true"
  export BUILDKITE_PULL_REQUEST="42"
  export BUILDKITE_REPO="git@github.com:example/repo.git"

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 0 ]

  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called" ]
  grep -q "refs/pull/42/merge" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/fetch_called"

  [ -f "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called" ]
  grep -q "FETCH_HEAD" "$BUILDKITE_BUILD_CHECKOUT_PATH/.git/checkout_called"
}

@test "Merge refspec fetch failure aborts the build" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"
  export BUILDKITE_PULL_REQUEST_USING_MERGE_REFSPEC="true"
  export BUILDKITE_PULL_REQUEST="42"
  export BUILDKITE_REPO="https://github.com/example/repo.git"

  # Override mock to fail only on merge ref fetch
  cat > "$BUILDKITE_BUILD_CHECKOUT_PATH/bin/git" <<'GITEOF'
#!/usr/bin/env bash
if [[ "$1" == "clone" ]]; then
  mkdir -p ".git"
  exit 0
fi
if [[ "$1" == "reset" ]]; then
  exit 0
fi
if [[ "$1" == "clean" ]]; then
  exit 0
fi
if [[ "$1" == "fetch" && "$*" == *"refs/pull"* ]]; then
  echo "[mock git] merge ref fetch failed" >&2
  exit 1
fi
exit 0
GITEOF
  chmod +x "$BUILDKITE_BUILD_CHECKOUT_PATH/bin/git"

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 1 ]
}

@test "Fails the build when fetch fails during persistent agent repo update" {
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_SKIP_CHECKOUT="false"
  export BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_URL="https://github.com/example/repo.git"

  # Simulate a pre-existing repository
  mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/.git"

  # Override the mock to fail on fetch so we can verify error propagation
  cat > "$BUILDKITE_BUILD_CHECKOUT_PATH/bin/git" <<'GITEOF'
#!/usr/bin/env bash
if [[ "$1" == "fetch" ]]; then
  echo "[mock git] fetch failed: network unreachable" >&2
  exit 1
fi
exit 0
GITEOF
  chmod +x "$BUILDKITE_BUILD_CHECKOUT_PATH/bin/git"

  run run_plugin_hook "checkout"

  echo "Output: $output"
  [ "$status" -eq 1 ]
}