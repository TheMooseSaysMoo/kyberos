# KyberOS distro layer: everything that differs between Fedora, Debian/Ubuntu and Arch.
# Sourced by install.sh and the system/ scripts. Families: fedora | debian | arch.
#   KYB_FAMILY             detected family (from /etc/os-release ID / ID_LIKE)
#   kyb_pkg <dep>...       package names for logical deps (rsvg xcursorgen kconfig kvantum
#                          plymouth-script shapes zstd gdbus python curl fontconfig)
#   kyb_installed <pkg>    is the package installed
#   kyb_install <pkg>...   install packages (run as root)
#   kyb_packages           sorted list of installed package names
#   kyb_dm                 active display manager: plasmalogin | sddm | lightdm | <other> | ""
#   kyb_desktop            plasma | cinnamon | unknown (KYBEROS_DESKTOP overrides)
#   kyb_plymouth_set <t>   set the boot splash theme and rebuild the initramfs (root)

kyb_family() {
    local id like
    id=$(. /etc/os-release 2>/dev/null; echo "${ID:-}")
    like=$(. /etc/os-release 2>/dev/null; echo "${ID_LIKE:-}")
    for x in $id $like; do
        case $x in
            fedora|rhel|centos|nobara|ultramarine) echo fedora; return ;;
            debian|ubuntu|neon|linuxmint|pop) echo debian; return ;;
            arch|archlinux|endeavouros|manjaro|cachyos|garuda) echo arch; return ;;
        esac
    done
    # last resort: whichever package manager is here
    if command -v dnf >/dev/null; then echo fedora
    elif command -v apt-get >/dev/null; then echo debian
    elif command -v pacman >/dev/null; then echo arch
    else echo unknown; fi
}
KYB_FAMILY=${KYB_FAMILY:-$(kyb_family)}

kyb_pkg() {
    local d
    for d in "$@"; do
        case $KYB_FAMILY:$d in
            fedora:rsvg) echo librsvg2-tools ;;     debian:rsvg) echo librsvg2-bin ;;      arch:rsvg) echo librsvg ;;
            fedora:xcursorgen) echo xcursorgen ;;   debian:xcursorgen) echo x11-apps ;;    arch:xcursorgen) echo xorg-xcursorgen ;;
            fedora:kconfig) echo kf6-kconfig ;;     debian:kconfig) echo libkf6config-bin ;; arch:kconfig) echo kconfig ;;
            fedora:kvantum) echo kvantum ;;         debian:kvantum) echo qt6-style-kvantum ;; arch:kvantum) echo kvantum ;;
            fedora:plymouth-script) echo plymouth-plugin-script ;; debian:plymouth-script) echo plymouth ;; arch:plymouth-script) echo plymouth ;;
            fedora:shapes) echo qt6-qtdeclarative ;; debian:shapes) echo qml6-module-qtquick-shapes ;; arch:shapes) echo qt6-declarative ;;
            fedora:gdbus) echo glib2 ;;             debian:gdbus) echo libglib2.0-bin ;;   arch:gdbus) echo glib2 ;;
            fedora:python) echo python3 ;;          debian:python) echo python3 ;;         arch:python) echo python ;;
            # Cinnamon side: the qml runtime + modules (scene renders), xrandr, dconf
            fedora:qml) echo qt6-qtdeclarative-devel ;;
            debian:qml) echo qt6-declarative-dev-tools qml6-module-qtquick qml6-module-qtquick-window qml6-module-qtquick-shapes qml6-module-qtqml-workerscript qml6-module-qtqml-models qml6-module-qtqml ;;
            arch:qml) echo qt6-declarative ;;
            fedora:xrandr) echo xrandr ;;           debian:xrandr) echo x11-xserver-utils ;; arch:xrandr) echo xorg-xrandr ;;
            fedora:dconf) echo dconf ;;             debian:dconf) echo dconf-cli ;;         arch:dconf) echo dconf ;;
            *:zstd) echo zstd ;; *:curl) echo curl ;; *:fontconfig) echo fontconfig ;;
            *) echo "kyb_pkg: no package for '$d' on '$KYB_FAMILY'" >&2 ;;
        esac
    done
}

kyb_installed() {
    case $KYB_FAMILY in
        fedora) rpm -q "$1" >/dev/null 2>&1 ;;
        debian) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed" ;;
        arch)   pacman -Q "$1" >/dev/null 2>&1 ;;
        *)      return 1 ;;
    esac
}

kyb_install() {
    [ $# -gt 0 ] || return 0
    case $KYB_FAMILY in
        fedora) dnf -y install "$@" ;;
        debian) export DEBIAN_FRONTEND=noninteractive
                apt-get -y install --no-install-recommends "$@" 2>/dev/null ||
                    { apt-get update && apt-get -y install --no-install-recommends "$@"; } ;;
        arch)   pacman -S --needed --noconfirm "$@" ;;
        *)      echo "don't know how to install packages on this distro: $*" >&2; return 1 ;;
    esac
}

kyb_packages() {
    case $KYB_FAMILY in
        fedora) rpm -qa --qf '%{NAME}\n' ;;
        debian) dpkg-query -W -f='${Package}\n' ;;
        arch)   pacman -Qq ;;
    esac | sort -u
}

kyb_dm() {
    local u
    u=$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" .service 2>/dev/null)
    if [ -z "$u" ] || [ "$u" = display-manager ]; then
        u=""
        for d in plasmalogin sddm lightdm; do systemctl is-enabled -q "$d" 2>/dev/null && { u=$d; break; }; done
    fi
    echo "$u"
}

kyb_desktop() {
    [ -n "${KYBEROS_DESKTOP:-}" ] && { echo "$KYBEROS_DESKTOP"; return; }
    case "${XDG_CURRENT_DESKTOP:-}" in
        *KDE*|*Plasma*) echo plasma; return ;;
        *Cinnamon*) echo cinnamon; return ;;
    esac
    # over ssh / from a tty: look at what is running, then at what is installed
    if pgrep -u "$(id -u)" -x plasmashell >/dev/null; then echo plasma
    elif pgrep -u "$(id -u)" -x cinnamon >/dev/null; then echo cinnamon
    elif command -v plasmashell >/dev/null; then echo plasma
    elif command -v cinnamon >/dev/null; then echo cinnamon
    else echo unknown; fi
}

kyb_initramfs() {
    if command -v update-initramfs >/dev/null; then update-initramfs -u
    elif command -v mkinitcpio >/dev/null; then mkinitcpio -P
    elif command -v dracut >/dev/null; then dracut -f
    else echo "no initramfs tool found; boot splash takes effect after the next initramfs rebuild" >&2; fi
}

kyb_plymouth_set() {
    command -v plymouth-set-default-theme >/dev/null || return 1
    if [ "$KYB_FAMILY" = fedora ]; then
        plymouth-set-default-theme -R "$1"       # Fedora's -R rebuilds with dracut
    else
        plymouth-set-default-theme "$1" && kyb_initramfs
    fi
}
