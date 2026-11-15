#!/bin/sh
# ===========================================================================
# Gonic entrypoint for a non-root container (TOS 7 requirement).
#
# The image listens on port 80 by default, which uid 1000 cannot bind, and it
# refuses to start until its podcast folder exists. This wrapper prepares the
# folders and starts gonic on the published port with explicit paths.
# ===========================================================================
set -e
set -u

for d in /data /data/podcasts /music /cache /playlists; do
  mkdir -p "$d" 2>/dev/null || true
done

if ! ( : > /data/.write-test ) 2>/dev/null; then
  echo "gonic: /data is not writable by uid $(id -u)" >&2
  exit 1
fi
rm -f /data/.write-test

exec gonic \
  -listen-addr 0.0.0.0:4747 \
  -music-path /music \
  -playlists-path /playlists \
  -podcast-path /data/podcasts \
  -cache-path /cache \
  -db-path /data/gonic.db
