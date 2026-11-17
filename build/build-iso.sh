#!/usr/bin/env bash
# Build the FocusWave ISO. Run as root on Fedora (a VM or container is best):
#
#   sudo ./build/build-iso.sh
#
# Environment:
#   FEDORA_VERSION  Fedora release to base on (default: the one this machine runs)
#   OUTPUT_DIR      where the ISO goes (default: ./output)
#   WORK_DIR        scratch space, needs ~25 GB free (default: /var/tmp/focuswave-build)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root:  sudo $0" >&2
    exit 1
fi
FEDORA_VERSION="${FEDORA_VERSION:-$(rpm -E %fedora)}"
OUT="${OUTPUT_DIR:-$ROOT/output}"
WORK="${WORK_DIR:-/var/tmp/focuswave-build}"
ISO_NAME="FocusWave-${FEDORA_VERSION}-x86_64.iso"

mkdir -p "$OUT/logs" "$OUT/rpms" "$WORK"
save_logs() {
    cp -rf "$WORK/logs/." "$OUT/logs/" 2>/dev/null || true
    cp -f /tmp/*.log "$OUT/logs/" 2>/dev/null || true
}
trap save_logs EXIT

echo "==> [1/5] Installing build tools for Fedora $FEDORA_VERSION"
dnf -y install \
    lorax lorax-lmc-novirt anaconda-tui anaconda-core pykickstart createrepo_c \
    rpm-build cmake gcc-c++ extra-cmake-modules qt6-qtbase-devel kf6-kwindowsystem-devel \
    kf6-kconfig-devel kf6-kcoreaddons-devel kdecoration-devel python3 systemd-rpm-macros \
    tar xz policycoreutils selinux-policy-targeted

echo "==> [2/5] Building FocusWave RPMs"
rm -rf "$WORK/repo"
DIST_DIR="$WORK/repo" bash "$ROOT/build/build-rpms.sh"
cp -f "$WORK"/repo/*.rpm "$OUT/rpms/"
createrepo_c "$WORK/repo"

EXTRA_PACKAGES=""
if ls "$WORK"/repo/focuswave-decoration-*.rpm >/dev/null 2>&1; then
    EXTRA_PACKAGES="focuswave-decoration"
fi

echo "==> [3/5] Preparing the kickstart"
sed -e "s|@FOCUSWAVE_REPO@|file://$WORK/repo|" \
    -e "s|@EXTRA_PACKAGES@|$EXTRA_PACKAGES|" \
    -e "s|@FEDORA_VERSION@|$FEDORA_VERSION|" \
    "$ROOT/kickstart/focuswave.ks.in" > "$WORK/focuswave.ks"
ksflatten -c "$WORK/focuswave.ks" -o "$WORK/focuswave-flat.ks"
cp -f "$WORK/focuswave-flat.ks" "$OUT/logs/"

echo "==> [4/5] Building the live image (this takes a while)"
setenforce 0 2>/dev/null || true
rm -rf "$WORK/lmc" "$WORK/tmp"
mkdir -p "$WORK/tmp" "$WORK/logs"
livemedia-creator \
    --ks "$WORK/focuswave-flat.ks" \
    --no-virt \
    --make-iso \
    --iso-only \
    --iso-name "$ISO_NAME" \
    --project FocusWave \
    --volid "FocusWave-$FEDORA_VERSION" \
    --releasever "$FEDORA_VERSION" \
    --nomacboot \
    --resultdir "$WORK/lmc" \
    --tmp "$WORK/tmp" \
    --logfile "$WORK/logs/livemedia.log"

echo "==> [5/5] Collecting the ISO"
mv -f "$WORK/lmc/$ISO_NAME" "$OUT/$ISO_NAME"
(cd "$OUT" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256")
ls -lh "$OUT/$ISO_NAME"
echo "Done: $OUT/$ISO_NAME"
