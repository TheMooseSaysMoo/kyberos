#!/usr/bin/env bash
# KyberOS system pieces (run as root by install.sh --system or system/rollout.sh):
#   - Plymouth boot splash 'kyberos' (rebuilds the initramfs with dracut, mkinitcpio or
#     update-initramfs, whichever the distro uses)
#   - login screen, for whichever display manager is active:
#       Plasma Login Manager -> tactical wallpaper + KyberOS style/colours/cursor/fonts
#       SDDM                 -> the 'kyberos' SDDM theme (same animated display + IDENTIFY panel)
# Fedora, Debian/Ubuntu and Arch. Package-managed files are never overwritten: assets go
# under /usr/local/share, /usr/share/{plymouth/themes,sddm/themes,icons}/<kyberos dirs>
# and config drop-ins. Undo with system/uninstall-system.sh.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/distro.sh"
DIST=$1
CRYSTAL=${2:-blue}
Cap=${CRYSTAL^}
[ "$(id -u)" = 0 ] || { echo "run as root" >&2; exit 1; }
say() { printf '\033[1;35m[kyberos]\033[0m %s\n' "$*"; }

LOCAL=/usr/local/share
STATE=/var/lib/kyberos
mkdir -p "$STATE"
DM=$(kyb_dm)
say "distro family: $KYB_FAMILY, display manager: ${DM:-none}"

# ---- fonts + cursor, readable by every greeter user ----
install -d "$LOCAL/fonts" "$LOCAL/icons"
user_home=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)
if [ -d "$user_home/.local/share/fonts/kyberos" ]; then
    rm -rf "$LOCAL/fonts/kyberos"
    cp -r "$user_home/.local/share/fonts/kyberos" "$LOCAL/fonts/kyberos"
    fc-cache -f "$LOCAL/fonts/kyberos" >/dev/null
fi
# Xcursor's default search path has /usr/share/icons but not /usr/local/share/icons
if [ -d "$DIST/icons/KyberOS-$Cap" ]; then
    rm -rf "/usr/share/icons/KyberOS-$Cap"
    cp -r "$DIST/icons/KyberOS-$Cap" /usr/share/icons/
fi
chmod -R a+rX "$LOCAL/fonts" /usr/share/icons/KyberOS-* 2>/dev/null || true

# ---- boot splash ----
if command -v plymouth-set-default-theme >/dev/null; then
    [ -f "$STATE/plymouth-previous" ] || plymouth-set-default-theme > "$STATE/plymouth-previous"
    kyb_installed "$(kyb_pkg plymouth-script)" || kyb_install $(kyb_pkg plymouth-script)
    rm -rf /usr/share/plymouth/themes/kyberos
    cp -r "$DIST/plymouth/kyberos" /usr/share/plymouth/themes/kyberos
    say "setting boot splash (rebuilding the initramfs, takes a minute)"
    kyb_plymouth_set kyberos
    # the splash only shows if the initramfs has plymouth and the kernel gets 'splash'
    grep -qw splash /proc/cmdline || say "note: kernel command line has no 'splash'; add 'quiet splash' to your bootloader to see the boot animation"
    if [ "$KYB_FAMILY" = arch ] && [ -f /etc/mkinitcpio.conf ] && ! grep -Eq '^HOOKS=.*plymouth' /etc/mkinitcpio.conf; then
        say "note: add 'plymouth' to HOOKS in /etc/mkinitcpio.conf and run 'mkinitcpio -P' to see the boot animation"
    fi
else
    say "plymouth not installed: skipping the boot splash"
fi

# ---- login screen ----
case $DM in
plasmalogin)
    install -d "$LOCAL/plasma/desktoptheme" "$LOCAL/plasma/wallpapers" "$LOCAL/color-schemes"
    rm -rf "$LOCAL/plasma/desktoptheme/KyberOS" "$LOCAL/plasma/wallpapers/org.kyberos.tactical"
    cp -r "$DIST/plasma/desktoptheme/KyberOS" "$LOCAL/plasma/desktoptheme/"
    cp -r "$DIST/plasma/wallpapers/org.kyberos.tactical" "$LOCAL/plasma/wallpapers/"
    cp "$DIST"/color-schemes/KyberOS*.colors "$LOCAL/color-schemes/"
    chmod -R a+rX "$LOCAL/plasma" "$LOCAL/color-schemes"
    mkdir -p /etc/plasmalogin.conf.d
    cat > /etc/plasmalogin.conf.d/50-kyberos.conf <<EOF
[Greeter]
WallpaperPluginId=org.kyberos.tactical

[Greeter][Wallpaper][org.kyberos.tactical][General]
Crystal=$CRYSTAL
Banner=IMPERIAL NETWORK  //  IDENTIFY
Animate=true
EOF
    # the greeter runs as 'plasmalogin' and reads its own ~/.config
    G=$(getent passwd plasmalogin | cut -d: -f6)/.config
    install -d -o plasmalogin -g plasmalogin -m 750 "$G"
    {
        cat "$DIST/color-schemes/KyberOS$Cap.colors"
        printf '\n[General]\nColorScheme=KyberOS%s\nfont=Exo 2,10,-1,5,500,0,0,0,0,0,0,0,0,0,0,1\n' "$Cap"
        printf '\n[Icons]\nTheme=breeze-dark\n'
    } > "$G/kdeglobals"
    printf '[Theme]\nname=KyberOS\n' > "$G/plasmarc"
    printf '[Mouse]\ncursorTheme=KyberOS-%s\ncursorSize=24\n' "$Cap" > "$G/kcminputrc"
    chown plasmalogin:plasmalogin "$G/kdeglobals" "$G/plasmarc" "$G/kcminputrc"
    say "Plasma Login Manager themed (applies at next logout/boot)"
    ;;
sddm)
    greeter6=$(command -v sddm-greeter-qt6 || ls /usr/lib*/sddm/sddm-greeter-qt6 /usr/libexec/sddm-greeter-qt6 2>/dev/null | head -1 || true)
    if [ -z "$greeter6" ]; then
        say "SDDM has no Qt 6 greeter (sddm-greeter-qt6) here: skipping the login theme"
    else
        kyb_installed "$(kyb_pkg shapes)" || kyb_install $(kyb_pkg shapes)
        rm -rf /usr/share/sddm/themes/kyberos
        cp -r "$DIST/sddm/kyberos" /usr/share/sddm/themes/kyberos
        printf '[General]\nCrystal=%s\nAnimate=true\n' "$CRYSTAL" > /usr/share/sddm/themes/kyberos/theme.conf.user
        chmod -R a+rX /usr/share/sddm/themes/kyberos
        mkdir -p /etc/sddm.conf.d
        # InputMethod= : Debian enables the Qt on-screen keyboard by default, which pops up over
        # the IDENTIFY panel on focus (touchscreen users can set InputMethod=qtvirtualkeyboard)
        printf '[General]\nInputMethod=\n\n[Theme]\nCurrent=kyberos\nCursorTheme=KyberOS-%s\nCursorSize=24\n' "$Cap" > /etc/sddm.conf.d/50-kyberos.conf
        say "SDDM themed (applies at next logout/boot; preview: sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/kyberos)"
    fi
    ;;
*)
    say "display manager '${DM:-none}' isn't SDDM or Plasma Login Manager: skipping the login theme"
    ;;
esac
