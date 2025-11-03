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

  mock_git_commands
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
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_USE_MIRROR
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_REPOS_0_MIRROR_NAME
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_USE_MIRROR
  unset BUILDKITE_PLUGIN_CUSTOM_CHECKOUT_MIRROR_PATH

  export PATH="$(echo "$PATH" | tr ':' '\n' | grep -v "$DEFAULT_BUILDKITE_BUILD_CHECKOUT_PATH/bin" | paste -sd ':' -)"
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

mock_git_commands() {
  export PATH="$BUILDKITE_BUILD_CHECKOUT_PATH/bin:$PATH"
  mkdir -p "$BUILDKITE_BUILD_CHECKOUT_PATH/bin"

  cat > "$BUILDKITE_BUILD_CHECKOUT_PATH/bin/git" <<'EOF'
#!/usr/bin/env bash
echo "[mock git] $@" >&2

# Handle clone --mirror specially
if [[ "$1" == "clone" && "$2" == "--mirror" ]]; then
  # Simulate mirror directory creation
  mkdir -p "$3"
  exit 0
fi

# Simulate standard clone: git clone <url> .
if [[ "$1" == "clone" ]]; then
  mkdir -p ".git"
  exit 0
fi

# Trackable fetch calls that can be read in tests, catching the command and reading it is as expected
if [[ "$1" == "fetch" ]]; then
  echo "$@" > ".git/fetch_called"
  exit 0
fi

# Simulate checkout, remote, lfs
if [[ "$1" == "checkout" || "$1" == "remote" || "$1" == "lfs" ]]; then
  exit 0
fi

exit 0
EOF

  chmod +x "$BUILDKITE_BUILD_CHECKOUT_PATH/bin/git"

# Mocking SSH-Keyscan for bats as no stub available
  cat > "$BUILDKITE_BUILD_CHECKOUT_PATH/bin/ssh-keyscan" <<'EOF'
echo "[mock ssh-keyscan] $@" >&2
# Output a mock host key for github.com
echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk="
exit 0
EOF

  chmod +x "$BUILDKITE_BUILD_CHECKOUT_PATH/bin/ssh-keyscan"

  cat > "$BUILDKITE_BUILD_CHECKOUT_PATH/bin/ssh-keygen" <<'EOF'
echo "[mock ssh-keygen] $@" >&2
echo "256 SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s github.com (RSA)"
exit 0
EOF

  chmod +x "$BUILDKITE_BUILD_CHECKOUT_PATH/bin/ssh-keygen"
}
