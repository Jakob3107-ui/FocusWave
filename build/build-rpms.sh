#!/usr/bin/env bash
# Build the FocusWave RPMs on Fedora.
#
#   ./build/build-rpms.sh                 -> RPMs in ./dist
#   DIST_DIR=/some/dir ./build/build-rpms.sh
#   INSTALL_DEPS=1 ./build/build-rpms.sh  -> also installs the build tools (uses sudo)
#
# focuswave-desktop must build. focuswave-decoration (the traffic-light buttons) is
# allowed to fail: FocusWave then falls back to Breeze buttons on the left.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${DIST_DIR:-$ROOT/dist}"
VERSION="$(sed -n 's/^Version:[[:space:]]*//p' "$ROOT/packaging/focuswave-desktop.spec")"
SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO="sudo"

BUILD_DEPS=(rpm-build cmake gcc-c++ extra-cmake-modules qt6-qtbase-devel kf6-kwindowsystem-devel
            kf6-kconfig-devel kf6-kcoreaddons-devel kdecoration-devel python3 systemd-rpm-macros tar)

if [ "${INSTALL_DEPS:-0}" = "1" ]; then
    echo "==> Installing build tools"
    $SUDO dnf -y install "${BUILD_DEPS[@]}"
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK"/{BUILD,RPMS,SOURCES,SPECS,SRPMS} "$DIST"

echo "==> Packing sources (focuswave-$VERSION)"
tar -C "$ROOT" \
    --exclude='./dist' --exclude='./output' --exclude='./.git' --exclude='__pycache__' \
    --transform "s|^\.|focuswave-$VERSION|" \
    -czf "$WORK/SOURCES/focuswave-$VERSION.tar.gz" .

build_spec() {
    rpmbuild --define "_topdir $WORK" -bb "$ROOT/packaging/$1.spec"
}

echo "==> Building focuswave-desktop"
build_spec focuswave-desktop

echo "==> Building focuswave-decoration (optional)"
if ! build_spec focuswave-decoration; then
    echo "WARNING: focuswave-decoration did not build. FocusWave will use Breeze buttons on the left" >&2
    echo "         instead of colored traffic lights. Everything else works." >&2
fi

find "$WORK/RPMS" -name '*.rpm' -exec cp -v {} "$DIST/" \;
echo "==> RPMs are in $DIST"
