#!/usr/bin/env bash
# Undo system/install-system.sh (run as root).
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run as root" >&2; exit 1; }
STATE=/var/lib/kyberos
LOCAL=/usr/local/share

if [ -f "$STATE/plymouth-previous" ]; then
    prev=$(cat "$STATE/plymouth-previous")
    echo "[kyberos] restoring boot splash '$prev' (rebuilding initramfs)"
    plymouth-set-default-theme -R "$prev"
fi
rm -rf /usr/share/plymouth/themes/kyberos

rm -f /etc/plasmalogin.conf.d/50-kyberos.conf
rm -f /var/lib/plasmalogin/.config/kdeglobals /var/lib/plasmalogin/.config/plasmarc /var/lib/plasmalogin/.config/kcminputrc
rm -rf "$LOCAL/plasma/desktoptheme/KyberOS" "$LOCAL/plasma/wallpapers/org.kyberos.tactical" "$LOCAL/fonts/kyberos"
rm -f "$LOCAL"/color-schemes/KyberOS*.colors
rm -rf "$LOCAL"/icons/KyberOS-*
rm -rf "$STATE"
echo "[kyberos] system pieces removed"
