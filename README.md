# Custom Checkout Buildkite Plugin 

A Buildkite plugin to specify a custom Git repository, branch, or commit to checkout in your pipeline steps, overriding the default repository configured in the pipeline settings.

### Required

#### `repository` (string)

The Git repository URL to clone.

### Optional

#### `commit` (string)

The Git commit SHA to checkout.

## Example

To skip your initial repository configured in your settings add the following to your `pipeline.yml`:

```yaml
steps:
  - label: "Build with Custom Repo"
    command: "buildkite-agent pipeline upload"
    plugins:
      - buildkite-plugins/custom-checkout#v1.0.0:
          skip_checkout: true
```

To checkout different repository then you specified in your settings:  

```yaml
steps:
  - label: "Build with Custom Repo"
    command: "buildkite-agent pipeline upload"
    plugins:
      - buildkite-plugins/custom-checkout#v1.0.0:
          skip_checkout: true
          repos:
            - url: "https://github.com/ivannalisetska/detect-clowns-buildkite-plugin.git"
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

## Developing

To run testing, shellchecks and plugin linting use use `bk run` with the [Buildkite CLI](https://github.com/buildkite/cli).

```bash
bk run
```

Or if you want to run just the tests, you can use the docker [Plugin Tester](https://github.com/buildkite-plugins/buildkite-plugin-tester):

```bash
docker run --rm -ti -v "${PWD}":/plugin buildkite/plugin-tester:latest
```



## 📜 License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
