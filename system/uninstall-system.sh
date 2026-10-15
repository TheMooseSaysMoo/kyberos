#!/usr/bin/env bash
# Undo system/install-system.sh (run as root). Works on Fedora, Debian/Ubuntu and Arch.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/distro.sh"
[ "$(id -u)" = 0 ] || { echo "run as root" >&2; exit 1; }
STATE=/var/lib/kyberos
LOCAL=/usr/local/share

if [ -f "$STATE/plymouth-previous" ]; then
    prev=$(cat "$STATE/plymouth-previous")
    echo "[kyberos] restoring boot splash '$prev' (rebuilding initramfs)"
    kyb_plymouth_set "$prev" || echo "[kyberos] could not restore '$prev'"
fi
rm -rf /usr/share/plymouth/themes/kyberos

# Plasma Login Manager
rm -f /etc/plasmalogin.conf.d/50-kyberos.conf
if G=$(getent passwd plasmalogin | cut -d: -f6) && [ -n "$G" ]; then
    rm -f "$G/.config/kdeglobals" "$G/.config/plasmarc" "$G/.config/kcminputrc"
fi
rm -rf "$LOCAL/plasma/desktoptheme/KyberOS" "$LOCAL/plasma/wallpapers/org.kyberos.tactical"
rm -f "$LOCAL"/color-schemes/KyberOS*.colors
# SDDM
rm -f /etc/sddm.conf.d/50-kyberos.conf
rm -rf /usr/share/sddm/themes/kyberos
# LightDM
if [ -f "$STATE/slick-greeter.conf.pre-kyberos" ]; then cp -a "$STATE/slick-greeter.conf.pre-kyberos" /etc/lightdm/slick-greeter.conf
elif [ -f "$STATE/slick-greeter.conf.absent" ]; then rm -f /etc/lightdm/slick-greeter.conf; fi
rm -f /etc/lightdm/lightdm-gtk-greeter.conf.d/50-kyberos.conf
rm -rf /usr/local/share/kyberos /usr/share/themes/KyberOS-* /usr/share/icons/KyberOS
# shared
rm -rf "$LOCAL/fonts/kyberos" "$LOCAL"/icons/KyberOS-* /usr/share/icons/KyberOS-*
rm -rf "$STATE"
echo "[kyberos] system pieces removed"
