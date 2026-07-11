# Contributing to provenant-action

Thanks for helping improve the Provenant GitHub Action. This is a small wrapper repository; the
scanner and its contributor guide live in the main project,
[`getprovenant/provenant`](https://github.com/getprovenant/provenant/blob/main/CONTRIBUTING.md).

## Ground rules

- **Sign off your commits** with `git commit -s` (Developer Certificate of Origin).
- Use **Conventional Commits** for commit messages and PR titles (e.g. `fix:`, `feat:`, `docs:`, `ci:`).
- Keep every source file's **SPDX headers** intact (`SPDX-FileCopyrightText` + `SPDX-License-Identifier: Apache-2.0`).
- Pin any third-party GitHub Action by commit SHA with a trailing `# vN` comment.
- Read [`AGENTS.md`](AGENTS.md) for the repo layout, how the wrapper image works, and the release flow.

## Testing a change

The `.github/workflows/ci.yml` self-test runs the action against the committed fixture in `testdata/`.
Run the action locally by building the image and invoking the entrypoint, e.g.:

```sh
docker build -t provenant-action-dev .
docker run --rm -v "$PWD:/github/workspace" -w /github/workspace provenant-action-dev \
  testdata json-pp - "--license --package"
```

Behavior questions about scanning, flags, or output belong in the main repository.
