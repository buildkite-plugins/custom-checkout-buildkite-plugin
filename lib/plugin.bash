#!/bin/bash
set -euo pipefail

PLUGIN_PREFIX="YOUR_PLUGIN_NAME"

# Reads either a value or a list from the given env prefix
function prefix_read_list() {
  local prefix="$1"
  local parameter="${prefix}_0"

  if [ -n "${!parameter:-}" ]; then
    local i=0
    local parameter="${prefix}_${i}"
    while [ -n "${!parameter:-}" ]; do
      echo "${!parameter}"
      i=$((i+1))
      parameter="${prefix}_${i}"
    done
  elif [ -n "${!prefix:-}" ]; then
    echo "${!prefix}"
  fi
}

# Reads either a value or a list from plugin config
function plugin_read_list() {
  prefix_read_list "BUILDKITE_PLUGIN_${PLUGIN_PREFIX}_${1}"
}


# Reads either a value or a list from plugin config into a global result array
# Returns success if values were read
function prefix_read_list_into_result() {
  local prefix="$1"
  local parameter="${prefix}_0"
  result=()

  if [ -n "${!parameter:-}" ]; then
    local i=0
    local parameter="${prefix}_${i}"
    while [ -n "${!parameter:-}" ]; do
      result+=("${!parameter}")
      i=$((i+1))
      parameter="${prefix}_${i}"
    done
  elif [ -n "${!prefix:-}" ]; then
    result+=("${!prefix}")
  fi

  [ ${#result[@]} -gt 0 ] || return 1
}

# Reads either a value or a list from plugin config
function plugin_read_list_into_result() {
  prefix_read_list_into_result "BUILDKITE_PLUGIN_${PLUGIN_PREFIX}_${1}"
}

# Reads a single value
function plugin_read_config() {
  local var="BUILDKITE_PLUGIN_${PLUGIN_PREFIX}_${1}"
  local default="${2:-}"
  echo "${!var:-$default}"
}

# clone_repository() {
#   local repo_url="$1"
#   local checkout_ref="$2"
#   local ssh_key_path="$3"
#   local clone_dir="$4"
#   local mirror_url="${5:-}"
#   local clone_flags=("${@:6}")

#   log_info "Cloning repository into '$clone_dir'"
#   mkdir -p "$clone_dir"
#   pushd "$clone_dir" > /dev/null

#   if [[ -n "$ssh_key_path" ]]; then
#     export GIT_SSH_COMMAND="ssh -i $ssh_key_path -o IdentitiesOnly=yes"
#   fi

#   if [[ -d ".git" ]]; then
#     log_info "Repository already exists. Fetching latest changes."
#     git fetch origin
#   else
#     if [[ -n "$mirror_url" ]]; then
#       log_info "Trying to clone from mirror: $mirror_url"
#       if git clone "${clone_flags[@]}" "$mirror_url" .; then
#         log_success "Cloned from mirror: $mirror_url"
#         git remote set-url origin "$repo_url"
#       else
#         log_warning "Mirror clone failed, falling back to original URL: $repo_url"
#         # Clean up failed clone attempt
#         rm -rf ./*
#         git clone "${clone_flags[@]}" "$repo_url" .
#       fi
#     else
#       git clone "${clone_flags[@]}" "$repo_url" .
#     fi
#   fi

#   popd > /dev/null
#   log_info "Repository cloned successfully"
#   return 0
# }