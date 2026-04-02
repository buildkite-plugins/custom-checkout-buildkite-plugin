# Custom Checkout Buildkite Plugin

A Buildkite plugin for customizing repository checkouts in your pipeline. This plugin allows you to:
- Skip the default repository checkout
- Check out multiple repositories
- Configure custom checkout paths

## Features

- 🚫 Skip default checkout
- 📁 Custom checkout paths
- 🔑 SSH key support
- 📦 Multiple repository support
- ♻️ Persistent agent support

## Configuration

### Basic Configuration

```yaml
steps:
  - label: "Skip checkout"
    command: 'echo "Skipping checkout"'
    plugins:
      - custom-checkout#v1.7.0:
          skip_checkout: true
```

### Advanced Configuration

```yaml
steps:
  - label: "Custom repository checkout"
    command: "buildkite-agent pipeline upload"
    plugins:
      - custom-checkout#v1.7.0:
          skip_checkout: true
          repos:
            - url: "https://github.com/org/repo.git"
              ref: "main"
```

## Configuration Options

### Plugin Options

| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| `skip_checkout` | false | `false` | Skip the default repository checkout |
| `repos` | false | `[]` | List of repositories to check out |
| `delete_checkout` | false | `false` | Delete checkout directory after build |
| `checkout_path` | false | `$BUILDKITE_BUILD_CHECKOUT_PATH` | Custom checkout path |

### Repository Options

Each repository in the `repos` list can have the following options:

| Option        | Required | Default  | Description                                 |
|---------------|----------|--------- |---------------------------------------------|
| `url`         | true     |          | Repository Git URL                          |
| `mirror_url`  | false    |          | Optional mirror URL for faster/local clone  |
| `ref`         | false    |          | Branch, tag, or commit to checkout          |
| `clone_flags` | false    | `["-v"]` | Additional flags for git clone              |
| `fetch`       | false    | `false`  | Perform git fetch after clone, before checkout |
| `fetch_flags` | false    | `[]`     | Additional flags for git fetch              |
| `checkout_path` | false  |          | Custom directory path for this repository  |

## Examples

### Skip Default Checkout

```yaml
steps:
  - label: "Skip checkout"
    command: 'echo "Skipping checkout"'
    plugins:
      - custom-checkout#v1.7.0:
          skip_checkout: true
```

### Custom Repository Checkout

```yaml
steps:
  - label: "Custom checkout"
    command: "buildkite-agent pipeline upload"
    plugins:
      - custom-checkout#v1.7.0:
          skip_checkout: true
          repos:
            - url: "https://github.com/org/repo.git"
```

### Multiple Repositories

```yaml
steps:
  - label: "Multiple repos"
    command: "./script.sh"
    plugins:
      - custom-checkout#v1.7.0:
          skip_checkout: true
          repos:
            - url: "https://github.com/org/repo1.git"
              ref: "main"
            - url: "https://github.com/org/repo2.git"
              ref: "dev"
```

### Custom Checkout Paths

```yaml
steps:
  - label: "Custom paths"
    command: "./script.sh"
    plugins:
      - custom-checkout#v1.7.0:
          skip_checkout: true
          repos:
            - url: "https://github.com/org/repo1.git"
              ref: "main"
              checkout_path: "/tmp/repo1"
            - url: "https://github.com/org/repo2.git"
              ref: "dev"
              checkout_path: "repo2"
```

### Clone with Mirror URL

```yaml
steps:
  - label: "Checkout with mirror"
    command: "buildkite-agent pipeline upload"
    plugins:
      - custom-checkout#v1.7.0:
          skip_checkout: true
          repos:
            - url: "https://github.com/org/repo.git"
              mirror_url: "https://git-mirror.local/org/repo.git"
              ref: "main"
```

### Shallow Clone with Fetch

```yaml
steps:
  - label: "Shallow clone with fetch"
    command: "buildkite-agent pipeline upload"
    plugins:
      - custom-checkout#v1.7.0:
          skip_checkout: true
          repos:
            - url: "https://github.com/org/repo.git"
              fetch: true
              clone_flags:
                - "--depth=1"
                - "--branch=main"
              fetch_flags:
                - "--depth=1"
```

### Pull Request Merge Refspec

When `BUILDKITE_PULL_REQUEST_USING_MERGE_REFSPEC` is enabled in your pipeline, the plugin automatically fetches and checks out GitHub's pre-computed merge commit (`refs/pull/N/merge`) instead of the PR head commit. This tests the result of merging the PR into its target branch.

This activates when all of the following are true:

- `BUILDKITE_PULL_REQUEST_USING_MERGE_REFSPEC` is `true`
- The build is for a pull request (`BUILDKITE_PULL_REQUEST` is a number)
- The repository URL matches `BUILDKITE_REPO`
- No explicit `ref` is configured for the repository

When using multiple repositories, merge refspec only applies to the repository that triggered the build. An explicit `ref` always takes precedence.

## Compatibility

| Elastic Stack | Agent Stack K8s | Hosted (Mac) | Hosted (Linux) | Notes |
| :-----------: | :-------------: | :----------: | :------------: |:----: |
| ✅ | ✅ | ✅ | ✅ | n/a |

- ✅ Fully supported (all combinations of attributes have been tested to pass)
- ⚠️ Partially supported (some combinations cause errors/issues)
- ❌ Not supported

## Developing

Run all tests:

```bash
docker compose run --rm tests
```

Run linter:

```bash
docker compose run --rm lint
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📜 License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
