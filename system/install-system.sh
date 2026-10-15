#!/usr/bin/env bash
# KyberOS system pieces (run as root by install.sh --system):
#   - Plymouth boot splash 'kyberos' (rebuilds the initramfs)
#   - Plasma Login Manager greeter: tactical wallpaper + KyberOS style/colours/cursor/fonts
# Everything goes under /usr/local/share or /etc/plasmalogin.conf.d, never over
# rpm-owned files. Undo with system/uninstall-system.sh.
set -euo pipefail
DIST=$1
CRYSTAL=${2:-blue}
Cap=${CRYSTAL^}
[ "$(id -u)" = 0 ] || { echo "run as root" >&2; exit 1; }

LOCAL=/usr/local/share
STATE=/var/lib/kyberos
mkdir -p "$STATE"

# ---- boot splash ----
if command -v plymouth-set-default-theme >/dev/null; then
    [ -f "$STATE/plymouth-previous" ] || plymouth-set-default-theme > "$STATE/plymouth-previous"
    rm -rf /usr/share/plymouth/themes/kyberos
    cp -r "$DIST/plymouth/kyberos" /usr/share/plymouth/themes/kyberos
    rpm -q plymouth-plugin-script >/dev/null || dnf -y install plymouth-plugin-script
    echo "[kyberos] setting boot splash (rebuilding initramfs, takes a minute)"
    plymouth-set-default-theme -R kyberos
fi

# ---- greeter assets, readable by the plasmalogin user ----
install -d "$LOCAL/plasma/desktoptheme" "$LOCAL/plasma/wallpapers" "$LOCAL/color-schemes" "$LOCAL/icons" "$LOCAL/fonts"
rm -rf "$LOCAL/plasma/desktoptheme/KyberOS" "$LOCAL/plasma/wallpapers/org.kyberos.tactical"
cp -r "$DIST/plasma/desktoptheme/KyberOS" "$LOCAL/plasma/desktoptheme/"
cp -r "$DIST/plasma/wallpapers/org.kyberos.tactical" "$LOCAL/plasma/wallpapers/"
cp "$DIST"/color-schemes/KyberOS*.colors "$LOCAL/color-schemes/"
rm -rf "$LOCAL/icons/KyberOS-$Cap"
cp -r "$DIST/icons/KyberOS-$Cap" "$LOCAL/icons/" 2>/dev/null || true
user_home=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)
if [ -d "$user_home/.local/share/fonts/kyberos" ]; then
    rm -rf "$LOCAL/fonts/kyberos"
    cp -r "$user_home/.local/share/fonts/kyberos" "$LOCAL/fonts/kyberos"
    fc-cache -f "$LOCAL/fonts/kyberos" >/dev/null
fi
chmod -R a+rX "$LOCAL/plasma" "$LOCAL/color-schemes" "$LOCAL/icons" "$LOCAL/fonts"

# ---- greeter configuration ----
cat > /etc/plasmalogin.conf.d/50-kyberos.conf <<EOF
[Greeter]
WallpaperPluginId=org.kyberos.tactical

[Greeter][Wallpaper][org.kyberos.tactical][General]
Crystal=$CRYSTAL
Banner=IMPERIAL NETWORK  //  IDENTIFY
Animate=true
EOF

# the greeter runs as 'plasmalogin' and reads its own ~/.config
G=/var/lib/plasmalogin/.config
install -d -o plasmalogin -g plasmalogin -m 750 "$G"
{
    cat "$DIST/color-schemes/KyberOS$Cap.colors"
    printf '\n[General]\nColorScheme=KyberOS%s\nfont=Exo 2,10,-1,5,500,0,0,0,0,0,0,0,0,0,0,1\n' "$Cap"
    printf '\n[Icons]\nTheme=breeze-dark\n'
} > "$G/kdeglobals"
printf '[Theme]\nname=KyberOS\n' > "$G/plasmarc"
printf '[Mouse]\ncursorTheme=KyberOS-%s\ncursorSize=24\n' "$Cap" > "$G/kcminputrc"
chown plasmalogin:plasmalogin "$G/kdeglobals" "$G/plasmarc" "$G/kcminputrc"
echo "[kyberos] login greeter themed (applies at next logout/boot)"
