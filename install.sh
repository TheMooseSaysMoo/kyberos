#!/usr/bin/env bash
# KyberOS installer (Plasma 6 on Fedora, Debian/Ubuntu or Arch).
#
#   ./install.sh                  build + install for this user, apply theme, keep panels
#   ./install.sh --layout         ...and replace the panel layout with the KyberOS one (pinned apps kept)
#   ./install.sh --crystal red    pick the kyber crystal (blue green red purple yellow white)
#   ./install.sh --system         also install the boot splash + login greeter theme (sudo)
#   ./install.sh --no-apply       install files only
#
# Every config file it touches is backed up once to ~/.local/share/kyberos/backup-original
# (uninstall.sh restores from there).
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib/distro.sh"
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
if ! command -v kpackagetool6 >/dev/null || ! command -v plasma-apply-lookandfeel >/dev/null; then
    echo "KyberOS needs KDE Plasma 6 (kpackagetool6 / plasma-apply-lookandfeel not found)." >&2
    exit 1
fi
[ "$KYB_FAMILY" = unknown ] && echo "  ! unrecognised distro: install librsvg (rsvg-convert), xcursorgen, kwriteconfig6, Kvantum (Qt6) and the QtQuick.Shapes QML module yourself" >&2
need=()
command -v rsvg-convert >/dev/null || need+=($(kyb_pkg rsvg))
command -v xcursorgen >/dev/null || need+=($(kyb_pkg xcursorgen))
command -v kwriteconfig6 >/dev/null || need+=($(kyb_pkg kconfig))
command -v gdbus >/dev/null || need+=($(kyb_pkg gdbus))
command -v python3 >/dev/null || need+=($(kyb_pkg python))
command -v curl >/dev/null || need+=($(kyb_pkg curl))
command -v fc-cache >/dev/null || need+=($(kyb_pkg fontconfig))
for d in kvantum shapes; do kyb_installed "$(kyb_pkg $d)" || need+=($(kyb_pkg $d)); done
if [ ${#need[@]} -gt 0 ] && [ "$KYB_FAMILY" != unknown ]; then
    say "installing: ${need[*]} ($KYB_FAMILY, sudo)"
    sudo bash -c ". '$HERE/lib/distro.sh'; kyb_install ${need[*]}"
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
# the menu button icon also goes into hicolor, the fallback every Plasma version searches
mkdir -p "$DATA/icons/hicolor/scalable/apps"
cp "$DIST/icons/KyberOS/scalable/apps/start-here-kyberos.svg" "$DATA/icons/hicolor/scalable/apps/"
mkdir -p "$CONF/Kvantum"
cp -r "$DIST/Kvantum/." "$CONF/Kvantum/"
mkdir -p "$DATA/plasma" "$DATA/kwin/effects" "$DATA/kwin/tabbox"
cp -r "$DIST/plasma/." "$DATA/plasma/"
cp -r "$DIST/kwin/effects/." "$DATA/kwin/effects/"
cp -r "$DIST/kwin/tabbox/." "$DATA/kwin/tabbox/"
mkdir -p "$HOME/.local/bin"
install -m 755 "$HERE/kyberos-crystal" "$HOME/.local/bin/kyberos-crystal"
install -m 755 "$HERE/kyberos-screens" "$HOME/.local/bin/kyberos-screens"
install -m 755 "$HERE/kyberos-greeting" "$HOME/.local/bin/kyberos-greeting"
mkdir -p "$CONF/systemd/user"
install -m 644 "$HERE/system/kyberos-screens.service" "$CONF/systemd/user/kyberos-screens.service"

if [ $APPLY = 1 ]; then
    say "applying KyberOS"
    # XWayland apps get the cursor/fonts via xrdb, which needs the X display
    if [ -z "${DISPLAY:-}" ]; then
        # take the session's own values (Xwayland is :0 on some distros, :1 on others)
        sp=$(pgrep -u "$(id -u)" -x plasmashell | head -1 || true)
        [ -n "$sp" ] && while IFS= read -r -d '' kv; do
            case $kv in DISPLAY=*|XAUTHORITY=*) export "$kv" ;; esac
        done < "/proc/$sp/environ"
    fi
    pshell() { gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell \
               --method org.kde.PlasmaShell.evaluateScript "$1" 2>/dev/null |
           python3 -c 'import ast, sys; print(ast.literal_eval(sys.stdin.read())[0])' 2>/dev/null; }
    if [ $LAYOUT = 1 ]; then
        # carry the pinned apps from the current task manager over to the KyberOS dock
        pinned=$(pshell '
            var l = "";
            panels().forEach(function (p) { p.widgets().forEach(function (w) {
                if (l || !/^org\.kde\.plasma\.(icon)?tasks$/.test(w.type)) return;
                w.currentConfigGroup = ["General"];
                var v = w.readConfig("launchers", "");
                l = (typeof v === "string") ? v : v.join(",");
            }) });
            print(l);')
        plasma-apply-lookandfeel -a org.kyberos.desktop --resetLayout
        if [ -n "$pinned" ]; then
            say "keeping your pinned apps in the dock"
            pshell "panels().forEach(function (p) { p.widgets('org.kde.plasma.icontasks').forEach(function (w) {
                    w.currentConfigGroup = ['General'];
                    w.writeConfig('launchers', '$pinned'.split(','));
                }) });" >/dev/null
        fi
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
    if kyb_installed "$(kyb_pkg kvantum)" || command -v kvantummanager >/dev/null; then
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
    # Alt+Tab: targeting console switcher
    w --file kwinrc --group TabBox --key LayoutName kyberos
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
    # a running KWin doesn't pick up effects installed after it started, even on reconfigure
    fx() { gdbus call --session --dest org.kde.KWin --object-path /Effects --method "org.kde.kwin.Effects.$1" "$2" >/dev/null 2>&1 || true; }
    for e in scale glide fade fadedesktop slide; do fx unloadEffect "$e"; done
    for e in kyberos_open kyberos_wipe; do fx loadEffect "$e"; done
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

cmd=kyberos-crystal
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) cmd="~/.local/bin/kyberos-crystal" ;; esac   # not on PATH on Arch by default
say "done. Crystal: $Cap. Switch any time with: $cmd <blue|green|red|purple|yellow|white>"
