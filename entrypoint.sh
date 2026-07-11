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
set -eu

paths="${1:-.}"
fmt="${2:-json-pp}"
outfile="${3:--}"
extra="${4:-}"

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
set -- scan $paths "$fmt_flag" "$outfile" $extra

echo "provenant-action: running: provenant $*" >&2
exec /usr/local/bin/provenant "$@"
