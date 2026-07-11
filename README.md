# Provenant GitHub Action

Run [Provenant](https://github.com/getprovenant/provenant) — the Rust,
ScanCode-compatible license, copyright, and SBOM scanner — in a GitHub Actions
workflow. This action wraps the published container image
[`ghcr.io/getprovenant/provenant`](https://github.com/getprovenant/provenant/pkgs/container/provenant)
so a scan needs no local toolchain.

## Usage

Minimal workflow — scan the checked-out repository and stream a pretty-printed
JSON report to the workflow log:

```yaml
name: License scan
on: [push, pull_request]

permissions:
  contents: read

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: getprovenant/provenant-action@v1
```

Write a report file and scan specific paths with a custom detection set:

```yaml
      - uses: getprovenant/provenant-action@v1
        with:
          paths: src testdata
          output-format: json
          output-file: provenant-results.json
          args: --license --package --copyright --info
      - uses: actions/upload-artifact@v7
        with:
          name: provenant-results
          path: provenant-results.json
```

### Scan only changed files (pull requests)

For fast pull-request checks, scan just the files that changed instead of the
whole tree. Produce a changed-file list with `git diff` and pass it as
`paths-file`:

```yaml
name: Changed-file license scan
on: pull_request

permissions:
  contents: read

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - name: List changed files
        run: git diff --name-only --diff-filter=d "origin/${{ github.base_ref }}...HEAD" > changed.txt
      - uses: getprovenant/provenant-action@v1
        with:
          paths-file: changed.txt
          args: --license --package --copyright
```

### Fail the build on a disallowed license

Provide a [license-policy file](https://github.com/getprovenant/provenant/blob/main/docs/CLI_GUIDE.md#the-license-policy-file)
that marks licenses with a `compliance_alert`, then gate on it. The job fails
when a matching license is found, and the SARIF file surfaces the violations as
pull-request and code-scanning alerts:

```yaml
permissions:
  contents: read
  security-events: write # to upload SARIF

jobs:
  license-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: getprovenant/provenant-action@v1
        with:
          license-policy: .github/license-policy.yml
          fail-on: error
          sarif-file: provenant.sarif
      - uses: github/codeql-action/upload-sarif@v3
        if: always() # upload findings even when the gate fails the job
        with:
          sarif_file: provenant.sarif
```

### Other scan options

Any `provenant scan` flag can be passed through `args` — for example
`--ignore "node_modules/*"` to skip noise or `--incremental` with a cached
`--cache-dir` to reuse work across runs. See the [CLI Guide](https://github.com/getprovenant/provenant/blob/main/docs/CLI_GUIDE.md)
for the full set of workflows and flags.

## Inputs

| Input           | Default             | Description                                                                                                                                                                              |
| --------------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `paths`         | `.`                 | Space-separated files or directories to scan, relative to the repository root. Defaults to the whole checkout.                                                                            |
| `output-format` | `json-pp`           | Output format. One of `json-pp`, `json`, `json-lines`, `yaml`, `cyclonedx`, `cyclonedx-xml`, `spdx-tv`, `spdx-rdf`, `debian`, `html`. Maps to the matching `provenant scan --<format>` flag. |
| `output-file`   | `-`                 | Where to write the report. `-` streams to stdout (the workflow log); any other value is a path written inside the workspace.                                                              |
| `args`          | `--license --package` | Extra raw arguments appended verbatim to `provenant scan`. Detections are opt-in — this is where you enable them (`--license`, `--package`, `--copyright`, `--info`, `--email`, `--url`, …). |
| `paths-file`    | _(empty)_           | Optional file listing exact files/directories to scan (one per line), relative to a single scan root in `paths`. Ideal for pull-request CI via `git diff --name-only`. When set, `paths` must stay a single root (the default `.`).                 |
| `license-policy` | _(empty)_          | Optional path to a YAML license-policy file. Enables policy evaluation; required by `fail-on` and by SARIF output.                                                                        |
| `fail-on`       | _(empty)_           | Fail the job (exit 3) when a file matches a policy whose `compliance_alert` is at or above this level: `error` or `warning`. Requires `license-policy`.                                    |
| `sarif-file`    | _(empty)_           | Also write SARIF 2.1.0 of policy violations to this path, for `github/codeql-action/upload-sarif`. Meaningful only with `license-policy`.                                                 |

Under the hood the action runs:

```sh
provenant scan <paths> [--paths-file <paths-file>] [--license-policy <file>] \
  [--fail-on <level>] [--sarif <sarif-file>] --<output-format> <output-file> <args>
```

## Outputs

This action does not set step outputs. Retrieve results by pointing
`output-file` at a path and uploading it with `actions/upload-artifact`, or by
reading the report streamed to the workflow log when `output-file` is `-`.

## Versioning

The action always runs the **latest** published Provenant release: its
[`Dockerfile`](Dockerfile) is `FROM ghcr.io/getprovenant/provenant:latest`, rebuilt on each run.
So the wrapped scanner advances automatically with every Provenant release — there is no per-release
update to this action.

You pin the **action's own** behavior by git ref:

- A **major version tag** (such as `@v1`) — the best default; picks up action fixes within that major.
- A **full commit SHA** — an exact, immutable pin of the action.

Because the action tracks `:latest`, `@vN` does not pin a fixed scanner version. If you need a
reproducible scanner version, pin the container directly instead (`docker run ghcr.io/getprovenant/provenant:<version> scan …`).

## How it works

The upstream image is distroless (no shell) and its entrypoint is the
`provenant` binary itself. To map the action inputs onto a `provenant scan`
invocation robustly, this action builds a thin wrapper image that `FROM`s
`ghcr.io/getprovenant/provenant` and adds a statically linked busybox shell so
[`entrypoint.sh`](entrypoint.sh) can assemble the command line. See the inline
comments in [`action.yml`](action.yml) and [`Dockerfile`](Dockerfile) for
details.

## License

Licensed under the [Apache License 2.0](LICENSE), matching the main Provenant
project.
