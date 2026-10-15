#!/usr/bin/env bash
# Put the desktop back exactly as tools/rollback/snapshot.sh recorded it.
#
#   tools/rollback/restore.sh                    restore the pre-KyberOS desktop
#   tools/rollback/restore.sh <stamp>            a specific snapshot (ls ~/KyberOS-Rollback)
#   tools/rollback/restore.sh --full             ...and EVERYTHING in user.tar.zst (all app configs,
#                                                not just the desktop; overwrites later app changes)
#   tools/rollback/restore.sh --system           ...and the boot splash + login greeter (sudo)
#
# Whatever it replaces is moved to <snapshot>/replaced-<time>/ first, so a restore can itself be undone.
# Works from a desktop terminal or a plain TTY/ssh; log out and back in afterwards for a clean session.
set -euo pipefail
HERE=$(cd "$(dirname "$0")/../.." && pwd)
STAMP=pre-kyberos FULL=0 SYSTEM=0
for a in "$@"; do
    case $a in
        --full) FULL=1 ;; --system) SYSTEM=1 ;;
        -h|--help) sed -n 2,11p "$0"; exit 0 ;;
        *) STAMP=$a ;;
    esac
done
SNAP=$(readlink -f "$HOME/KyberOS-Rollback/$STAMP")
TAR=$SNAP/user.tar.zst
[ -f "$TAR" ] || { echo "no snapshot at $HOME/KyberOS-Rollback/$STAMP" >&2; exit 1; }
say() { printf '\033[1;36m[restore]\033[0m %s\n' "$*"; }
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}

say "checking $SNAP"
(cd "$SNAP" && sha256sum --quiet -c SHA256SUMS) || { echo "snapshot checksum mismatch, stopping" >&2; exit 1; }

# everything the KyberOS install (theme apply, layout, effects, Kvantum, GTK sync) can touch
DESKTOP=(
    .config/kdeglobals .config/kwinrc .config/kwinrulesrc .config/plasmarc .config/kcminputrc
    .config/ksplashrc .config/kscreenlockerrc .config/konsolerc .config/plasmashellrc
    .config/plasma-org.kde.plasma.desktop-appletsrc .config/kglobalshortcutsrc .config/ksmserverrc
    .config/plasmanotifyrc .config/breezerc .config/kdedefaults .config/Kvantum
    .config/gtk-3.0 .config/gtk-4.0 .config/xsettingsd .gtkrc-2.0 .config/systemd/user
    .local/share/plasma .local/share/kwin .local/share/color-schemes .local/share/aurorae
    .local/share/konsole .local/share/wallpapers .local/share/icons .local/share/sounds
    .local/share/fonts .local/share/kscreen .local/share/plasmashell
    .local/bin/kyberos-crystal .local/bin/kyberos-screens .local/bin/kyberos-greeting
    .local/bin/kyberos-wallpaper .local/bin/kyberos-live
    .config/cinnamon .local/share/themes .local/share/cinnamon
    .config/autostart/kyberos-wallpaper.desktop .config/autostart/kyberos-live.desktop
    .local/share/kyberos
)

systemctl --user disable --now kyberos-screens.service 2>/dev/null || true
pkill -f "kyberos-wallpaper --watch" 2>/dev/null || true
pkill -f "kyberos/backdrop/live.qml" 2>/dev/null || true

ASIDE=$SNAP/replaced-$(date +%Y%m%d-%H%M%S)
say "moving the current desktop files aside -> $ASIDE"
cd "$HOME"
for p in "${DESKTOP[@]}"; do
    [ -e "$p" ] || [ -L "$p" ] || continue
    mkdir -p "$ASIDE/$(dirname "$p")"
    mv "$p" "$ASIDE/$p"
done

say "restoring from $TAR"
if [ $FULL = 1 ]; then
    tar --zstd -xpf "$TAR" -C "$HOME"
else
    in_tar=$(tar --zstd -tf "$TAR" | sed 's#/$##')
    want=()
    for p in "${DESKTOP[@]}"; do grep -qxF "$p" <<<"$in_tar" && want+=("$p"); done
    tar --zstd -xpf "$TAR" -C "$HOME" "${want[@]}"
fi

fc-cache -f >/dev/null 2>&1 || true
kbuildsycoca6 >/dev/null 2>&1 || true

# Cinnamon/GNOME settings live in dconf: load the dumps taken with the snapshot
if command -v dconf >/dev/null && ls "$SNAP"/state/dconf-*.ini >/dev/null 2>&1; then
    cp=""; for c in $(pgrep -u "$(id -u)" -x cinnamon); do [ -r "/proc/$c/environ" ] && { cp=$c; break; }; done   # skip zombies
    [ -n "$cp" ] && while IFS= read -r -d '' kv; do
        case ${kv%%=*} in DISPLAY|XAUTHORITY|DBUS_SESSION_BUS_ADDRESS) export "$kv" ;; esac
    done < "/proc/$cp/environ"
    for f in "$SNAP"/state/dconf-*.ini; do
        tree=$(basename "$f" .ini); tree=${tree#dconf-}; tree=/org/${tree//-//}/
        [ -s "$f" ] || continue
        dconf reset -f "$tree" && dconf load "$tree" < "$f"
    done
    say "restored dconf settings (Cinnamon, terminal, interface, Nemo)"
fi
systemctl --user daemon-reload

if [ $SYSTEM = 1 ]; then
    say "restoring the system side (sudo)"
    sudo "$HERE/system/restore-system.sh" "$STAMP"
fi

if pgrep -u "$(id -u)" -x kwin_wayland >/dev/null; then
    gdbus call --session --dest org.kde.KWin --object-path /KWin --method org.kde.KWin.reconfigure >/dev/null 2>&1 || true
    systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
fi
say "restored $(basename "$SNAP"). Log out and back in so every app picks the old style up."
