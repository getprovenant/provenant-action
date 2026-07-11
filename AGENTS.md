# Agent Guidelines for provenant-action

This repository is the **GitHub Action** wrapper for [Provenant](https://github.com/getprovenant/provenant),
the Rust, ScanCode-compatible license/copyright/SBOM scanner. It is intentionally tiny: it does not
contain the scanner, only a thin Docker container action that runs the published image.

## What this repo is

- A Docker container action (`runs.using: docker`). It builds a wrapper image that `FROM`s
  `ghcr.io/getprovenant/provenant` and adds a static busybox `sh` so `entrypoint.sh` can map the
  action inputs onto a `provenant scan` command line.
- The scanner itself, its docs, and its release pipeline live in the main repo
  [`getprovenant/provenant`](https://github.com/getprovenant/provenant). Behavior questions about
  scanning, flags, or output belong there.

## Key files

- `action.yml` — action metadata, inputs, and the fixed positional arg order passed to the entrypoint.
- `Dockerfile` — the wrapper image. Its `FROM ghcr.io/getprovenant/provenant:<tag>` line **pins the
  wrapped Provenant version** for a given action release.
- `entrypoint.sh` — assembles and execs `provenant scan` from the four positional inputs. Keep it
  POSIX `sh` (busybox), and keep `paths`/`args` word-splitting intentional (see the inline comments).
- `.github/workflows/ci.yml` — self-test that runs the action against `testdata/`.

## Conventions (mirror the main repo)

- Every source file carries SPDX headers (`SPDX-FileCopyrightText` + `SPDX-License-Identifier: Apache-2.0`).
- Sign off commits with `git commit -s` (DCO).
- Use Conventional Commits for commit messages and PR titles.
- Pin third-party GitHub Actions by commit SHA (with a trailing `# vN` comment), matching the main repo.

## Versioning and releases

- The `Dockerfile` is `FROM ghcr.io/getprovenant/provenant:latest`, so the action **auto-tracks the
  newest Provenant release** — GitHub rebuilds the image on each run and pulls `:latest`. There is
  **no per-Provenant-release commit or re-release of this action**; publish it once and it follows
  Provenant forward.
- Cut an action release only for changes to the **action itself** (inputs, entrypoint, docs): tag
  `vX.Y.Z` and move the floating `vX` tag. Consumers pin `@vN` or a full SHA.
- Trade-off: `@vN` is not pinned to a fixed scanner version. If reproducible version pinning is ever
  needed without per-release commits, convert to a composite action running
  `docker run …:${{ inputs.version }}` (default `latest`).
