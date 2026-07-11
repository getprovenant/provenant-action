# SPDX-FileCopyrightText: Provenant contributors
# SPDX-License-Identifier: Apache-2.0
#
# Thin wrapper around the published Provenant image. The upstream image is
# distroless (no shell), so we copy a statically linked busybox `sh` in purely
# to run entrypoint.sh, which maps the action inputs onto `provenant scan`.
#
# The `FROM` tag below pins which Provenant version this action wraps. Bump it
# when cutting a new action release; consumers pin the action with a git ref.
FROM busybox:1.37.0-musl AS busybox

FROM ghcr.io/getprovenant/provenant:latest

# Static busybox needs no libc, so it runs on the distroless base as-is.
COPY --from=busybox /bin/busybox /bin/busybox
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/busybox", "sh", "/entrypoint.sh"]
