#!/usr/bin/env bash
# KyberOS installer (Plasma 6 / Fedora).
#
#   ./install.sh                  build + install for this user, apply theme, keep panels
#   ./install.sh --layout         ...and replace the panel layout with the KyberOS one
#   ./install.sh --crystal red    pick the kyber crystal (blue green red purple yellow white)
#   ./install.sh --system         also install the boot splash + login greeter theme (sudo)
#   ./install.sh --no-apply       install files only
#
# Every config file it touches is backed up once to ~/.local/share/kyberos/backup-original
# (uninstall.sh restores from there).
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
CONF=${XDG_CONFIG_HOME:-$HOME/.config}
STATE=$DATA/kyberos
CRYSTAL=blue
LAYOUT=0
SYSTEM=0
APPLY=1

while [ $# -gt 0 ]; do
    case $1 in
        --layout) LAYOUT=1 ;;
        --system) SYSTEM=1 ;;
        --no-apply) APPLY=0 ;;
        --crystal) CRYSTAL=$2; shift ;;
        -h|--help) sed -n 2,12p "$0"; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done
case $CRYSTAL in blue|green|red|purple|yellow|white) ;; *) echo "bad crystal: $CRYSTAL" >&2; exit 2 ;; esac
Cap=${CRYSTAL^}

say() { printf '\033[1;36m[kyberos]\033[0m %s\n' "$*"; }

# ---- dependencies ------------------------------------------------------
need=()
command -v rsvg-convert >/dev/null || need+=(librsvg2-tools)
command -v xcursorgen >/dev/null || need+=(xcursorgen)
command -v kwriteconfig6 >/dev/null || need+=(kf6-kconfig)
rpm -q kvantum >/dev/null 2>&1 || need+=(kvantum)
if [ ${#need[@]} -gt 0 ]; then
    say "installing build tools: ${need[*]} (sudo)"
    sudo dnf -y install "${need[@]}"
fi

# ---- fonts (SIL OFL, from google/fonts) ---------------------------------
FONTDIR=$DATA/fonts/kyberos
fonts=(
    "orbitron/Orbitron%5Bwght%5D.ttf"
    "michroma/Michroma-Regular.ttf"
    "sharetechmono/ShareTechMono-Regular.ttf"
    "exo2/Exo2%5Bwght%5D.ttf"
    "exo2/Exo2-Italic%5Bwght%5D.ttf"
)
mkdir -p "$FONTDIR"
fetched=0
for f in "${fonts[@]}"; do
    name=$(basename "$f" | sed 's/%5B/[/; s/%5D/]/')
    if [ ! -s "$FONTDIR/$name" ]; then
        curl -fsSL "https://github.com/google/fonts/raw/main/ofl/$f" -o "$FONTDIR/$name" && fetched=1 ||
            echo "  ! could not fetch font $name (offline?)"
    fi
done
[ -s "$FONTDIR/OFL.txt" ] || curl -fsSL "https://github.com/google/fonts/raw/main/ofl/orbitron/OFL.txt" -o "$FONTDIR/OFL.txt" || true
[ $fetched = 1 ] && fc-cache -f "$FONTDIR" >/dev/null

# ---- build ---------------------------------------------------------------
say "building assets"
KYBEROS_CRYSTAL=$CRYSTAL python3 "$HERE/build/build.py" "$HERE/dist" | sed 's/^/  /'
DIST=$HERE/dist

# ---- back up config once -------------------------------------------------
BACKUP=$STATE/backup-original
CONFIGS=(kdeglobals kwinrc plasmarc kcminputrc ksplashrc kscreenlockerrc konsolerc
         plasma-org.kde.plasma.desktop-appletsrc plasmashellrc Kvantum/kvantum.kvconfig)
if [ ! -d "$BACKUP" ]; then
    mkdir -p "$BACKUP"
    for c in "${CONFIGS[@]}"; do
        [ -f "$CONF/$c" ] && mkdir -p "$BACKUP/$(dirname "$c")" && cp -a "$CONF/$c" "$BACKUP/$c"
    done
    kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage > "$BACKUP/lookandfeel" || true
    say "backed up current settings to $BACKUP"
fi

# ---- install files -------------------------------------------------------
say "installing into $DATA"
for sub in color-schemes aurorae konsole wallpapers icons sounds; do
    mkdir -p "$DATA/$sub"
    cp -r "$DIST/$sub/." "$DATA/$sub/"
done
mkdir -p "$CONF/Kvantum"
cp -r "$DIST/Kvantum/." "$CONF/Kvantum/"
mkdir -p "$DATA/plasma" "$DATA/kwin/effects"
cp -r "$DIST/plasma/." "$DATA/plasma/"
cp -r "$DIST/kwin/effects/." "$DATA/kwin/effects/"
mkdir -p "$HOME/.local/bin"
install -m 755 "$HERE/kyberos-crystal" "$HOME/.local/bin/kyberos-crystal"
install -m 755 "$HERE/kyberos-screens" "$HOME/.local/bin/kyberos-screens"
mkdir -p "$CONF/systemd/user"
install -m 644 "$HERE/system/kyberos-screens.service" "$CONF/systemd/user/kyberos-screens.service"

if [ $APPLY = 1 ]; then
    say "applying KyberOS"
    # XWayland apps get the cursor/fonts via xrdb, which needs the X display
    if [ -z "${DISPLAY:-}" ]; then
        export DISPLAY=:0
        xa=$(ls /run/user/$(id -u)/xauth_* 2>/dev/null | head -1)
        [ -n "$xa" ] && export XAUTHORITY=$xa
    fi
    if [ $LAYOUT = 1 ]; then
        plasma-apply-lookandfeel -a org.kyberos.desktop --resetLayout
    else
        plasma-apply-lookandfeel -a org.kyberos.desktop
    fi
    w() { kwriteconfig6 "$@"; }
    # fonts
    w --file kdeglobals --group General --key font "Exo 2,10,-1,5,500,0,0,0,0,0,0,0,0,0,0,1"
    w --file kdeglobals --group General --key menuFont "Exo 2,10,-1,5,500,0,0,0,0,0,0,0,0,0,0,1"
    w --file kdeglobals --group General --key toolBarFont "Exo 2,9,-1,5,500,0,0,0,0,0,0,0,0,0,0,1"
    w --file kdeglobals --group General --key smallestReadableFont "Exo 2,8,-1,5,500,0,0,0,0,0,0,0,0,0,0,1"
    w --file kdeglobals --group General --key fixed "Share Tech Mono,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    w --file kdeglobals --group WM --key activeFont "Orbitron,9,-1,5,600,0,0,0,0,0,0,0,0,0,0,1"
    # app widgets: Kvantum (chamfered steel controls) when available
    if rpm -q kvantum >/dev/null 2>&1; then
        w --file kdeglobals --group KDE --key widgetStyle kvantum
    fi
    # sounds
    w --file kdeglobals --group Sounds --key Theme KyberOS
    w --file kdeglobals --group Sounds --key Enable true
    # terminal
    w --file konsolerc --group "Desktop Entry" --key DefaultProfile KyberOS.profile
    # window effects: KyberOS open/close + wipe replace the stock animations
    w --file kwinrc --group Plugins --key kyberos_openEnabled true
    w --file kwinrc --group Plugins --key kyberos_wipeEnabled true
    for e in scale glide fade fadedesktop slide; do
        w --file kwinrc --group Plugins --key "${e}Enabled" false
    done
    # lock screen: tactical wallpaper with a banner
    w --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kyberos.tactical
    w --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kyberos.tactical --group General --key Banner "AUTHORIZATION REQUIRED"
    # desktop wallpaper (the layout script does this too when --layout is used)
    gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell \
        --method org.kde.PlasmaShell.evaluateScript "
        desktops().forEach(function (d) {
            d.wallpaperPlugin = 'org.kyberos.tactical';
            d.currentConfigGroup = ['Wallpaper', 'org.kyberos.tactical', 'General'];
            d.writeConfig('Animate', 'true');
        });" >/dev/null 2>&1 || echo "  ! could not set the wallpaper (is plasmashell running?)"
    "$HOME/.local/bin/kyberos-crystal" "$CRYSTAL" --quiet
    # new monitors get the animated wallpaper too
    systemctl --user daemon-reload
    systemctl --user enable --now kyberos-screens.service 2>/dev/null || true
    # make sure Plasma picks up the new wallpaper plugin, icons and panels
    systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
fi

# ---- system pieces (sudo) -------------------------------------------------
if [ $SYSTEM = 1 ]; then
    say "installing system pieces (sudo): boot splash + login greeter"
    sudo "$HERE/system/install-system.sh" "$DIST" "$CRYSTAL"
fi

say "done. Crystal: $Cap. Switch any time with: kyberos-crystal <blue|green|red|purple|yellow|white>"
