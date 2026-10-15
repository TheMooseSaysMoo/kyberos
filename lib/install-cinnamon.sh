# Cinnamon half of install.sh (sourced after the shared deps/fonts/build steps).
# Uses: HERE DIST DATA CONF STATE CRYSTAL Cap LAYOUT APPLY LIVE say
# Every setting it changes is backed up once (dconf dumps + panel applet configs) to
# $STATE/backup-original-cinnamon; uninstall.sh restores from there.

cin_session_env() {
    # from ssh/a tty: borrow the running Cinnamon session's display + bus
    local cp kv name
    cp=$(pgrep -u "$(id -u)" -x cinnamon | head -1 || true)
    [ -n "$cp" ] || return 0
    while IFS= read -r -d '' kv; do
        name=${kv%%=*}
        case $name in
            DISPLAY|XAUTHORITY|DBUS_SESSION_BUS_ADDRESS) [ -z "${!name:-}" ] && export "$kv" ;;
        esac
    done < "/proc/$cp/environ"
}

cin_backup() {
    local b=$STATE/backup-original-cinnamon
    [ -d "$b" ] && return 0
    mkdir -p "$b"
    dconf dump /org/cinnamon/ > "$b/cinnamon.dconf" 2>/dev/null || true
    dconf dump /org/gnome/terminal/ > "$b/terminal.dconf" 2>/dev/null || true
    dconf dump /org/gnome/desktop/interface/ > "$b/gnome-interface.dconf" 2>/dev/null || true
    [ -d "$CONF/cinnamon/spices" ] && cp -a "$CONF/cinnamon/spices" "$b/spices"
    [ -e "$CONF/gtk-4.0" ] && cp -a "$CONF/gtk-4.0" "$b/gtk-4.0"
    say "backed up current Cinnamon settings to $b"
}

cin_install_files() {
    say "installing into $DATA"
    mkdir -p "$DATA/themes" "$DATA/cinnamon/applets" "$DATA/cinnamon/extensions" "$STATE"
    for t in "$DIST"/themes/KyberOS-*; do rm -rf "$DATA/themes/$(basename "$t")"; done
    cp -r "$DIST/themes/." "$DATA/themes/"
    for sub in icons sounds wallpapers; do
        mkdir -p "$DATA/$sub"
        cp -r "$DIST/$sub/." "$DATA/$sub/"
    done
    for kind in applets extensions; do
        for d in "$DIST/cinnamon/$kind"/*; do
            rm -rf "$DATA/cinnamon/$kind/$(basename "$d")"
            cp -r "$d" "$DATA/cinnamon/$kind/"
        done
    done
    rm -rf "$STATE/backdrop" "$STATE/autostart" "$STATE/gnome-terminal"
    cp -r "$DIST/cinnamon/backdrop" "$STATE/backdrop"
    cp -r "$DIST/gnome-terminal" "$STATE/gnome-terminal"
    cp -r "$HERE/src/cinnamon/autostart" "$STATE/autostart"
    mkdir -p "$HOME/.local/bin"
    for s in kyberos-crystal kyberos-greeting kyberos-wallpaper kyberos-live; do
        install -m 755 "$HERE/$s" "$HOME/.local/bin/$s"
    done
}

cin_terminal() {
    local uuid list
    uuid=$(cat "$DIST/gnome-terminal/uuid")
    dconf load "/org/gnome/terminal/legacy/profiles:/:$uuid/" < "$DIST/gnome-terminal/KyberOS$Cap.dconf"
    list=$(gsettings get org.gnome.Terminal.ProfilesList list 2>/dev/null || echo "@as []")
    case $list in
        *"$uuid"*) ;;
        "@as []"|"[]") gsettings set org.gnome.Terminal.ProfilesList list "['$uuid']" ;;
        *) gsettings set org.gnome.Terminal.ProfilesList list "${list%]}, '$uuid']" ;;
    esac
    gsettings set org.gnome.Terminal.ProfilesList default "$uuid" 2>/dev/null || true
}

cin_gtk4() {
    # libadwaita / GTK 4 apps ignore gtk-theme; they read ~/.config/gtk-4.0/gtk.css
    local g=$CONF/gtk-4.0 t=$DATA/themes/KyberOS-$Cap/gtk-4.0
    mkdir -p "$g"
    for f in gtk.css gtk-dark.css assets; do
        if [ -e "$g/$f" ] && [ ! -L "$g/$f" ]; then mv "$g/$f" "$g/$f.pre-kyberos"; fi
        ln -sfn "$t/$f" "$g/$f"
    done
}

cin_spice_set() {
    # cin_spice_set <applet uuid> <instance> key=<json value>...: edit an applet's settings once
    # Cinnamon has written them (it watches the file and applies changes live)
    local uuid=$1 id=$2 f
    shift 2
    f=$CONF/cinnamon/spices/$uuid/$id.json
    for _ in $(seq 1 30); do [ -f "$f" ] && break; sleep 0.5; done
    [ -f "$f" ] || return 1
    python3 - "$f" "$@" <<'PY'
import json, sys
path, pairs = sys.argv[1], sys.argv[2:]
cfg = json.load(open(path))
for pair in pairs:
    k, v = pair.split("=", 1)
    k = k.strip('"')
    cfg.setdefault(k, {"type": "generic"})["value"] = json.loads(v)
json.dump(cfg, open(path, "w"), indent=4)
PY
}

cin_layout() {
    # top strip: menu, workspaces | clock | diagnostics, tray, status; bottom: centred task bar
    local pinned_json="" f
    for f in "$CONF"/cinnamon/spices/grouped-window-list@cinnamon.org/*.json; do
        [ -f "$f" ] || continue
        pinned_json=$(python3 -c 'import json,sys; v=json.load(open(sys.argv[1])).get("pinned-apps",{}).get("value"); print(json.dumps(v) if v else "")' "$f" 2>/dev/null)
        [ -n "$pinned_json" ] && break
    done
    gsettings set org.cinnamon panels-enabled "['1:0:top', '2:0:bottom']"
    gsettings set org.cinnamon panels-height "['1:34', '2:46']"
    gsettings set org.cinnamon panel-zone-icon-sizes '[{"panelId": 1, "left": 0, "center": 0, "right": 16}, {"panelId": 2, "left": 0, "center": 32, "right": 0}]' 2>/dev/null || true
    gsettings set org.cinnamon enabled-applets "[
        'panel1:left:0:menu@cinnamon.org:101', 'panel1:left:1:workspace-switcher@cinnamon.org:102',
        'panel1:center:0:calendar@cinnamon.org:103',
        'panel1:right:0:kyberos-diagnostics@kyberos:104', 'panel1:right:1:systray@cinnamon.org:105',
        'panel1:right:2:xapp-status@cinnamon.org:106', 'panel1:right:3:notifications@cinnamon.org:107',
        'panel1:right:4:network@cinnamon.org:108', 'panel1:right:5:sound@cinnamon.org:109',
        'panel1:right:6:power@cinnamon.org:110',
        'panel2:center:0:grouped-window-list@cinnamon.org:111']"
    [ -n "$pinned_json" ] && cin_spice_set grouped-window-list@cinnamon.org 111 "pinned-apps=$pinned_json" &&
        say "kept your pinned apps in the task bar"
    cin_spice_set menu@cinnamon.org 101 'menu-custom=true' '"menu-icon"="start-here-kyberos"' 'menu-icon-size=22' '"menu-label"=""'  || true
    cin_spice_set calendar@cinnamon.org 103 'use-custom-format=true' '"custom-format"="%Y-%m-%d   %H:%M"' || true
}

cin_apply() {
    say "applying KyberOS (Cinnamon)"
    local gs="gsettings set"
    $gs org.cinnamon.desktop.interface gtk-theme "KyberOS-$Cap"
    $gs org.cinnamon.desktop.wm.preferences theme "KyberOS-$Cap"
    $gs org.cinnamon.theme name "KyberOS-$Cap"
    $gs org.cinnamon.desktop.interface icon-theme KyberOS
    $gs org.cinnamon.desktop.interface cursor-theme "KyberOS-$Cap"
    $gs org.gnome.desktop.interface cursor-theme "KyberOS-$Cap" 2>/dev/null || true
    $gs org.cinnamon.desktop.interface font-name "Exo 2 10"
    $gs org.gnome.desktop.interface document-font-name "Exo 2 10" 2>/dev/null || true
    $gs org.gnome.desktop.interface monospace-font-name "Share Tech Mono 11" 2>/dev/null || true
    $gs org.cinnamon.desktop.wm.preferences titlebar-font "Orbitron Semi-Bold 10"
    $gs org.nemo.desktop font "Exo 2 10" 2>/dev/null || true
    $gs org.cinnamon.desktop.sound theme-name KyberOS 2>/dev/null || true
    $gs org.cinnamon.desktop.sound event-sounds true 2>/dev/null || true
    cin_gtk4
    cin_terminal
    # window effects: KyberOS holoprojector extension
    local ext
    ext=$(gsettings get org.cinnamon enabled-extensions)
    case $ext in
        *kyberos-effects@kyberos*) ;;
        "@as []"|"[]") $gs org.cinnamon enabled-extensions "['kyberos-effects@kyberos']" ;;
        *) $gs org.cinnamon enabled-extensions "${ext%]}, 'kyberos-effects@kyberos']" ;;
    esac
    [ $LAYOUT = 1 ] && cin_layout
    "$HOME/.local/bin/kyberos-crystal" "$CRYSTAL" --quiet
    # per-monitor wallpaper now, and re-rendered whenever monitors change
    mkdir -p "$CONF/autostart"
    cp "$STATE/autostart/kyberos-wallpaper.desktop" "$CONF/autostart/"
    pkill -f "kyberos-wallpaper --watch" 2>/dev/null || true
    "$HOME/.local/bin/kyberos-wallpaper" >/dev/null || say "  ! could not render the wallpaper (qml runtime missing?)"
    setsid "$HOME/.local/bin/kyberos-wallpaper" --watch >/dev/null 2>&1 < /dev/null &
    [ "${LIVE:-0}" = 1 ] && "$HOME/.local/bin/kyberos-live" on
    return 0
}

cinnamon_install() {
    cin_session_env
    cin_backup
    cin_install_files
    [ $APPLY = 1 ] && cin_apply
    return 0
}
