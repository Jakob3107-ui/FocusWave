#!/usr/bin/env bash
# Build the FocusWave ISO inside a Fedora container. Works on any Linux with podman or docker
# (this is also what the GitHub Actions workflow runs).
#
#   ./build/build-in-container.sh
#
# Environment: FEDORA_VERSION (default 45), OUTPUT_DIR (default ./output),
#              SCRATCH_DIR (optional big disk for temporary files, ~25 GB),
#              CONTAINER_ENGINE (podman or docker; auto-detected)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEDORA_VERSION="${FEDORA_VERSION:-45}"
OUT="${OUTPUT_DIR:-$ROOT/output}"
ENGINE="${CONTAINER_ENGINE:-$(command -v podman || command -v docker || true)}"
if [ -z "$ENGINE" ]; then
    echo "Please install podman or docker first." >&2
    exit 1
fi
mkdir -p "$OUT"

args=(run --rm --privileged --network host
      -v /dev:/dev
      -v "$ROOT:/focuswave"
      -v "$OUT:/output"
      -e "FEDORA_VERSION=$FEDORA_VERSION"
      -e "OUTPUT_DIR=/output")
if [ -n "${SCRATCH_DIR:-}" ]; then
    mkdir -p "$SCRATCH_DIR"
    args+=(-v "$SCRATCH_DIR:/work" -e "WORK_DIR=/work")
fi

echo "==> Building FocusWave on Fedora $FEDORA_VERSION with $(basename "$ENGINE")"
"$ENGINE" "${args[@]}" "registry.fedoraproject.org/fedora:$FEDORA_VERSION" \
    bash /focuswave/build/build-iso.sh
