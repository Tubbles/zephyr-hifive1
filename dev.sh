#!/usr/bin/env bash
#
# Thin wrapper: run any command inside the pinned Zephyr build environment.
# Prepend this script to whatever you want to run; everything after it runs
# verbatim in the container. It knows nothing about the Makefile or any recipe.
#
# Examples (from the repo root):
#   ./dev.sh make update                                 # fetch the workspace (once)
#   ./dev.sh make build                                  # via the Makefile
#   ./dev.sh west build -b hifive1_revb app -d build      # raw west
#   ./dev.sh west boards
#   ./dev.sh bash
#
# The repo IS the west workspace topdir: it is mounted at /work (the working
# directory), and `make update` fetches zephyr/, modules/, ... into it (all
# gitignored). The image carries only tools, so ZEPHYR_BASE points at the
# zephyr checkout inside the mounted repo. Build output lands in ./build.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="${ZEPHYR_IMAGE:-zephyr-hifive1:v4.4.1}"

# Build the image on first use (or after you delete it / bump west.yml).
if ! podman image inspect "$IMAGE" >/dev/null 2>&1; then
  echo ">> building $IMAGE (clones Zephyr + downloads the SDK; takes a while) ..." >&2
  podman build -t "$IMAGE" "$REPO_DIR"
fi

tty_flags=()
[ -t 0 ] && [ -t 1 ] && tty_flags=(-it)

# --userns=keep-id + :z: rootless-podman/SELinux handling so artifacts come out
# owned by you. HOME=/tmp gives CMake/west a writable cache dir. The repo is
# mounted as the west topdir and ZEPHYR_BASE points at the zephyr checkout the
# workspace fetched into it.
exec podman run --rm "${tty_flags[@]}" \
  --userns=keep-id \
  -e HOME=/tmp \
  -e ZEPHYR_BASE=/work/zephyr \
  -v "$REPO_DIR":/work:z \
  -w /work \
  "$IMAGE" \
  "$@"
