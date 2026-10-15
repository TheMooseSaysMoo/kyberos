#!/usr/bin/env bash
# Snapshot this user's whole desktop setup BEFORE KyberOS goes on, so it can be put back
# exactly (tools/rollback/restore.sh). Run as the desktop user, inside the session.
#
#   tools/rollback/snapshot.sh            -> ~/KyberOS-Rollback/<stamp>/
#
# What goes in:
#   user.tar.zst   all of ~/.config, ~/.local/share (minus big app payloads: Steam, Wine
#                  prefixes, Flatpak apps, PWAs, ...), ~/.local/bin, ~/.local/state, dotfiles
#   state/         readable dumps: panel/widget layout, theme keys, screens, user units,
#                  installed Plasma packages, so you can see what was there at a glance
#   SHA256SUMS
# Lives outside ~/.local/share/kyberos on purpose: uninstall.sh deletes that directory.
set -uo pipefail

STAMP=${1:-$(date +%Y%m%d-%H%M%S)}
OUT=$HOME/KyberOS-Rollback/$STAMP
mkdir -p "$OUT/state"
say() { printf '\033[1;36m[snapshot]\033[0m %s\n' "$*"; }

# session environment, so this also works from ssh
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}

# ---- files ----
say "archiving desktop files -> $OUT/user.tar.zst"
cd "$HOME"
paths=(.config .local/share .local/bin .local/state)
for f in .bashrc .bash_profile .profile .gtkrc-2.0 .gtkrc-2.0-kde4 .Xresources .xprofile .xsettingsd .kde .kde4 .themes .icons .fonts; do
    [ -e "$f" ] && paths+=("$f")
done
excludes=(
    --exclude=.local/share/Steam --exclude=.local/share/wineprefixes --exclude=.local/share/flatpak
    --exclude=.local/share/firefoxpwa --exclude=.local/share/streamdock-linux --exclude=.local/share/Trash
    --exclude=.local/share/baloo --exclude=.local/share/containers --exclude=.local/share/kyberos
    --exclude='.config/*/Cache' --exclude='.config/*/CachedData' --exclude='.config/*/GPUCache'
    --exclude='.config/*/Code Cache' --exclude='.config/*/Service Worker/CacheStorage'
)
tar --zstd -cf "$OUT/user.tar.zst" --warning=no-file-changed --warning=no-file-removed \
    --ignore-failed-read "${excludes[@]}" "${paths[@]}" 2>"$OUT/state/tar-warnings.txt"
rc=$?
# 1 = some live file changed while being read (browsers, editors): harmless here
[ $rc -le 1 ] || { echo "tar failed ($rc), see $OUT/state/tar-warnings.txt" >&2; exit 1; }
printf '%s\n' "${excludes[@]}" | sed 's/^--exclude=//' > "$OUT/state/excluded.txt"

# ---- readable state ----
say "recording theme, panels and screens"
r() { kreadconfig6 --file "$1" --group "$2" --key "$3" 2>/dev/null; }
{
    echo "LookAndFeel      $(r kdeglobals KDE LookAndFeelPackage)"
    echo "WidgetStyle      $(r kdeglobals KDE widgetStyle)"
    echo "ColorScheme      $(r kdeglobals General ColorScheme)"
    echo "PlasmaStyle      $(r plasmarc Theme name)"
    echo "Icons            $(r kdeglobals Icons Theme)"
    echo "Cursor           $(r kcminputrc Mouse cursorTheme)"
    echo "Decoration       $(r kwinrc org.kde.kdecoration2 library) $(r kwinrc org.kde.kdecoration2 theme)"
    echo "Splash           $(r ksplashrc KSplash Theme)"
    echo "Sounds           $(r kdeglobals Sounds Theme)"
    echo "Font             $(r kdeglobals General font)"
    echo "TabBox           $(r kwinrc TabBox LayoutName)"
    echo "KonsoleProfile   $(r konsolerc 'Desktop Entry' DefaultProfile)"
    echo "LockWallpaper    $(r kscreenlockerrc Greeter WallpaperPlugin)"
} > "$OUT/state/theme.txt"
grep -A100 '^\[Plugins\]' "$HOME/.config/kwinrc" 2>/dev/null | sed '/^$/q' > "$OUT/state/kwin-plugins.txt"

gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell \
    --method org.kde.PlasmaShell.evaluateScript '
    var out = [];
    panels().forEach(function (p) {
        out.push({ panel: p.id, screen: p.screen, location: p.location, height: p.height,
                   lengthMode: p.lengthMode, hiding: p.hiding, floating: p.floating,
                   widgets: p.widgets().map(function (w) { return w.type }) });
    });
    desktops().forEach(function (d) {
        out.push({ desktop: d.id, screen: d.screen, wallpaper: d.wallpaperPlugin });
    });
    print(JSON.stringify(out, null, 2));' > "$OUT/state/plasma-layout.txt" 2>&1 \
    || echo "plasmashell not reachable" > "$OUT/state/plasma-layout.txt"

kscreen-doctor -o 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' > "$OUT/state/screens.txt"
systemctl --user list-unit-files --state=enabled --no-legend > "$OUT/state/user-units.txt" 2>/dev/null
for t in Plasma/LookAndFeel Plasma/Theme Plasma/Wallpaper Plasma/Applet KWin/Effect KWin/WindowSwitcher; do
    echo "== $t"; kpackagetool6 --type "$t" --list 2>/dev/null | tail -n +2
done > "$OUT/state/plasma-packages.txt"
ls "$HOME/.config/Kvantum" > "$OUT/state/kvantum.txt" 2>/dev/null
[ -f "$HOME/.config/Kvantum/kvantum.kvconfig" ] && cat "$HOME/.config/Kvantum/kvantum.kvconfig" >> "$OUT/state/kvantum.txt"
cat "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" > "$OUT/state/appletsrc.ini" 2>/dev/null

(cd "$OUT" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
# the first snapshot taken is the pre-KyberOS one; later snapshots never move this link
[ -e "$HOME/KyberOS-Rollback/pre-kyberos" ] || ln -s "$STAMP" "$HOME/KyberOS-Rollback/pre-kyberos"
say "done: $OUT ($(du -sh "$OUT" | cut -f1))"
