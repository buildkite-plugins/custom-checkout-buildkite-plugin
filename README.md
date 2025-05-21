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

## Configuration

### Basic Configuration

```yaml
steps:
  - label: "Skip checkout"
    command: 'echo "Skipping checkout"'
    plugins:
      - custom-checkout#v1.2.1:
          skip_checkout: true
```

### Advanced Configuration

```yaml
steps:
  - label: "Custom repository checkout"
    command: "buildkite-agent pipeline upload"
    plugins:
      - custom-checkout#v1.2.1:
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

| Option        | Required | Default | Description                                 |
|---------------|----------|---------|---------------------------------------------|
| `url`         | true     |         | Repository Git URL                          |
| `mirror_url`  | false    |         | Optional mirror URL for faster/local clone  |
| `ref`         | false    |         | Branch, tag, or commit to checkout          |
| `clone_flags` | false    | `[]`    | Additional flags for git clone              |

## Examples

### Skip Default Checkout

```yaml
steps:
  - label: "Skip checkout"
    command: 'echo "Skipping checkout"'
    plugins:
      - custom-checkout#v1.2.1:
          skip_checkout: true
```

### Custom Repository Checkout

```yaml
steps:
  - label: "Custom checkout"
    command: "buildkite-agent pipeline upload"
    plugins:
      - custom-checkout#v1.2.1:
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
      - custom-checkout#v1.2.1:
          skip_checkout: true
          repos:
            - url: "https://github.com/org/repo1.git"
              ref: "main"
            - url: "https://github.com/org/repo2.git"
              ref: "dev"
```

### Clone with Mirror URL

```yaml
steps:
  - label: "Checkout with mirror"
    command: "buildkite-agent pipeline upload"
    plugins:
      - custom-checkout#v1.1.0:
          skip_checkout: true
          repos:
            - url: "https://github.com/org/repo.git"
              mirror_url: "https://git-mirror.local/org/repo.git"
              ref: "main"
```

## Testing

```bash
docker-compose run --rm tests
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📜 License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
