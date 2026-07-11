#!/bin/sh
# SPDX-FileCopyrightText: Provenant contributors
# SPDX-License-Identifier: Apache-2.0
#
# Assemble and exec `provenant scan` from the action inputs. Positional args are
# passed by action.yml in a fixed order:
#   $1 = paths (space-separated, word-split intentionally)
#   $2 = output-format (bare name, e.g. json-pp)
#   $3 = output-file ("-" for stdout, or a path)
#   $4 = extra args (raw flags, word-split intentionally)
#   $5 = paths-file (optional; a --paths-file list, empty to skip)
#   $6 = license-policy (optional; a --license-policy file, empty to skip)
#   $7 = fail-on (optional; error|warning, empty to skip)
#   $8 = sarif-file (optional; a --sarif output path, empty to skip)
set -eu

paths="${1:-.}"
fmt="${2:-json-pp}"
outfile="${3:--}"
extra="${4:-}"
pathsfile="${5:-}"
policy="${6:-}"
failon="${7:-}"
sariffile="${8:-}"

case "$fmt" in
  json | json-pp | json-lines | yaml | cyclonedx | cyclonedx-xml | spdx-tv | spdx-rdf | debian | html)
    fmt_flag="--$fmt"
    ;;
  *)
    echo "provenant-action: unsupported output-format '$fmt'" >&2
    exit 2
    ;;
esac

# Start argv with the subcommand, then the scan targets. `paths` and `extra` are
# deliberately left unquoted so multiple space-separated tokens split into
# separate arguments; an empty value expands to nothing.
# shellcheck disable=SC2086
set -- scan $paths
# `--paths-file` restricts the scan to a rooted list (e.g. changed files in CI).
# It requires exactly one scan root, so keep `paths` a single root when using it.
if [ -n "$pathsfile" ]; then
  set -- "$@" --paths-file "$pathsfile"
fi
# License policy, the CI gate, and SARIF output. `--fail-on` and SARIF both need a
# policy to be meaningful; the CLI validates the `--fail-on` requirement.
if [ -n "$policy" ]; then
  set -- "$@" --license-policy "$policy"
fi
if [ -n "$failon" ]; then
  set -- "$@" --fail-on "$failon"
fi
if [ -n "$sariffile" ]; then
  set -- "$@" --sarif "$sariffile"
fi
# shellcheck disable=SC2086
set -- "$@" "$fmt_flag" "$outfile" $extra

echo "provenant-action: running: provenant $*" >&2
exec /usr/local/bin/provenant "$@"
