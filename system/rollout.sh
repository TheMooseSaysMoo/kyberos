#!/usr/bin/env bash
# The one sudo step of a KyberOS rollout:
#   1. snapshot the system side (system/snapshot-system.sh)
#   2. install the build/runtime packages (rsvg-convert, xcursorgen, kvantum, plymouth script plugin)
#   3. fetch fonts + build + copy the user files as the calling user (install.sh --no-apply;
#      nothing visible changes yet, but the greeter needs those fonts)
#   4. install the boot splash + login greeter (system/install-system.sh)
# The user half (./install.sh, no sudo needed once step 2 is done) runs afterwards.
#
#   sudo system/rollout.sh [crystal]
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo" >&2; exit 1; }
HERE=$(cd "$(dirname "$0")/.." && pwd)
CRYSTAL=${1:-blue}
U=${SUDO_USER:?run with sudo from the desktop user}

"$HERE/system/snapshot-system.sh"
echo "[kyberos] installing packages"
dnf -y install librsvg2-tools xcursorgen kf6-kconfig kvantum plymouth-plugin-script
echo "[kyberos] building as $U"
sudo -u "$U" -H "$HERE/install.sh" --no-apply --crystal "$CRYSTAL"
"$HERE/system/install-system.sh" "$HERE/dist" "$CRYSTAL"
echo "[kyberos] system half done; the desktop half is ./install.sh"
