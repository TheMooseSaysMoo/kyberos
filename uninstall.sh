#!/usr/bin/env bash
# Remove KyberOS and restore the settings backed up by install.sh.
#   ./uninstall.sh            user pieces
#   ./uninstall.sh --system   also boot splash + login greeter (sudo)
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
CONF=${XDG_CONFIG_HOME:-$HOME/.config}
STATE=$DATA/kyberos
BACKUP=$STATE/backup-original

# a stock look that exists on this distro
stock() {
    for l in org.fedoraproject.fedora.desktop org.kde.breezedark.desktop org.kde.breeze.desktop; do
        kpackagetool6 --type Plasma/LookAndFeel --show "$l" >/dev/null 2>&1 && { echo "$l"; return; }
    done
    echo org.kde.breeze.desktop
}
say() { printf '\033[1;36m[kyberos]\033[0m %s\n' "$*"; }
. "$HERE/lib/distro.sh"

# ---- Cinnamon ----
if [ "$(kyb_desktop)" = cinnamon ]; then
    . "$HERE/lib/install-cinnamon.sh"
    cin_session_env
    CB=$STATE/backup-original-cinnamon
    pkill -f "kyberos-wallpaper --watch" 2>/dev/null || true
    pkill -f "kyberos/backdrop/live.qml" 2>/dev/null || true
    rm -f "$CONF/autostart/kyberos-wallpaper.desktop" "$CONF/autostart/kyberos-live.desktop"
    if [ -d "$CB" ]; then
        dconf reset -f /org/cinnamon/ && dconf load /org/cinnamon/ < "$CB/cinnamon.dconf"
        [ -s "$CB/terminal.dconf" ] && dconf reset -f /org/gnome/terminal/ && dconf load /org/gnome/terminal/ < "$CB/terminal.dconf"
        [ -s "$CB/gnome-interface.dconf" ] && dconf load /org/gnome/desktop/interface/ < "$CB/gnome-interface.dconf"
        if [ -d "$CB/spices" ]; then rm -rf "$CONF/cinnamon/spices"; cp -a "$CB/spices" "$CONF/cinnamon/spices"; fi
        say "restored Cinnamon settings from $CB"
    else
        say "no backup found; switching to the Mint-Y look"
        gsettings set org.cinnamon.desktop.interface gtk-theme Mint-Y-Dark-Aqua 2>/dev/null || true
        gsettings set org.cinnamon.theme name Mint-Y-Dark-Aqua 2>/dev/null || true
        gsettings set org.cinnamon.desktop.wm.preferences theme Mint-Y 2>/dev/null || true
    fi
    # GTK 4: drop our links, put back what was there
    for f in gtk.css gtk-dark.css assets; do
        [ -L "$CONF/gtk-4.0/$f" ] && rm -f "$CONF/gtk-4.0/$f"
        [ -e "$CONF/gtk-4.0/$f.pre-kyberos" ] && mv "$CONF/gtk-4.0/$f.pre-kyberos" "$CONF/gtk-4.0/$f"
    done
    rm -rf "$DATA"/themes/KyberOS-* "$DATA"/icons/KyberOS* "$DATA/sounds/KyberOS" "$DATA"/wallpapers/KyberOS-* \
           "$DATA/cinnamon/applets/kyberos-diagnostics@kyberos" "$DATA/cinnamon/extensions/kyberos-effects@kyberos" "$DATA/fonts/kyberos"
    rm -f "$HOME"/.local/bin/kyberos-{crystal,greeting,wallpaper,live}
    fc-cache -f >/dev/null 2>&1 || true
    [ "${1:-}" = --system ] && sudo "$HERE/system/uninstall-system.sh"
    rm -rf "$STATE"
    say "KyberOS removed"
    exit 0
fi

# ---- Plasma ----

if [ -d "$BACKUP" ]; then
    prev=$(cat "$BACKUP/lookandfeel" 2>/dev/null || true)
    plasma-apply-lookandfeel -a "${prev:-$(stock)}" >/dev/null 2>&1 || true
    (cd "$BACKUP" && find . -type f ! -name lookandfeel) | while read -r rel; do
        mkdir -p "$CONF/$(dirname "$rel")"
        cp -a "$BACKUP/$rel" "$CONF/$rel"
    done
    # no Kvantum config before KyberOS: drop ours
    [ -f "$BACKUP/Kvantum/kvantum.kvconfig" ] || rm -f "$CONF/Kvantum/kvantum.kvconfig"
    say "restored settings from $BACKUP"
else
    say "no backup found; switching to the stock look"
    plasma-apply-lookandfeel -a "$(stock)" >/dev/null 2>&1 || true
fi

rm -f "$DATA"/color-schemes/KyberOS*.colors "$DATA"/konsole/KyberOS*
rm -f "$DATA/icons/hicolor/scalable/apps/start-here-kyberos.svg"
rm -rf "$DATA"/aurorae/themes/KyberOS-* "$DATA"/wallpapers/KyberOS-* "$DATA"/icons/KyberOS* "$DATA/sounds/KyberOS"
rm -rf "$DATA/plasma/desktoptheme/KyberOS" "$DATA/plasma/look-and-feel/org.kyberos.desktop" \
       "$DATA/plasma/wallpapers/org.kyberos.tactical" "$DATA/plasma/plasmoids/org.kyberos.diagnostics"
rm -rf "$DATA"/kwin/effects/kyberos_* "$DATA/kwin/tabbox/kyberos" "$DATA/fonts/kyberos" "$CONF"/Kvantum/KyberOS-*
systemctl --user disable --now kyberos-screens.service 2>/dev/null || true
rm -f "$CONF/systemd/user/kyberos-screens.service"
rm -f "$HOME/.local/bin/kyberos-crystal" "$HOME/.local/bin/kyberos-screens" "$HOME/.local/bin/kyberos-greeting"
fc-cache -f >/dev/null 2>&1 || true

if [ "${1:-}" = --system ]; then
    sudo "$HERE/system/uninstall-system.sh"
fi
rm -rf "$STATE"

systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
gdbus call --session --dest org.kde.KWin --object-path /KWin --method org.kde.KWin.reconfigure >/dev/null 2>&1 || true
say "KyberOS removed"
