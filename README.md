# Custom Checkout Buildkite Plugin 

A Buildkite plugin to specify a custom Git repository, branch, or commit to checkout in your pipeline steps, overriding the default repository configured in the pipeline settings.

### Required

#### `repository` (string)

The Git repository URL to clone.

### Optional

#### `branch` (string)

The Git branch to checkout.

#### `commit` (string)

The Git commit SHA to checkout.

## Example

Add the following to your `pipeline.yml`:

```yaml
steps:
  - label: "Build with Custom Repo"
    plugins:
      - buildkite-plugins/custom-checkout#v1.0.0:
          repository: "git@github.com:buildkite-plugins/custom-checkout-buildkite-plugin.git"
          branch: "main"
    command: "your_command"
```

## ⚒ Developing

You can use the [bk cli](https://github.com/buildkite/cli) to run the [pipeline](.buildkite/pipeline.yml) locally:

```bash
bk local run
```

## 👩‍💻 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request


## 📜 License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
