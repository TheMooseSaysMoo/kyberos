#!/usr/bin/env bash
# The one sudo step of a KyberOS rollout:
#   1. snapshot the system side (system/snapshot-system.sh)
#   2. install the build/runtime packages (rsvg-convert, xcursorgen, kvantum, plymouth script
#      plugin, ...) with dnf, apt or pacman
#   3. fetch fonts + build + copy the user files as the calling user (install.sh --no-apply;
#      nothing visible changes yet, but the greeter needs those fonts)
#   4. install the boot splash + login greeter (system/install-system.sh)
# The user half (./install.sh, no sudo needed once step 2 is done) runs afterwards.
#
#   sudo system/rollout.sh [crystal]
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo" >&2; exit 1; }
HERE=$(cd "$(dirname "$0")/.." && pwd)
. "$HERE/lib/distro.sh"
CRYSTAL=${1:-blue}
U=${SUDO_USER:?run with sudo from the desktop user}

"$HERE/system/snapshot-system.sh"
echo "[kyberos] installing packages ($KYB_FAMILY)"
if [ "$(sudo -u "$U" bash -c ". '$HERE/lib/distro.sh'; kyb_desktop")" = cinnamon ]; then
    pk=$(kyb_pkg rsvg xcursorgen qml xrandr dconf gdbus python curl fontconfig zstd)
else
    pk=$(kyb_pkg rsvg xcursorgen kconfig kvantum shapes gdbus python curl fontconfig zstd)
fi
kyb_has_plymouth && pk="$pk $(kyb_pkg plymouth-script)"
kyb_install $pk
echo "[kyberos] building as $U"
sudo -u "$U" -H "$HERE/install.sh" --no-apply --crystal "$CRYSTAL"
"$HERE/system/install-system.sh" "$HERE/dist" "$CRYSTAL"
echo "[kyberos] system half done; the desktop half is ./install.sh"
