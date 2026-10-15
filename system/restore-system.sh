#!/usr/bin/env bash
# Put the boot splash + login greeter back as system/snapshot-system.sh recorded them (run as root).
#
#   sudo system/restore-system.sh [stamp]        default: the pre-KyberOS snapshot
#
# Heavier fallbacks, listed in <snapshot>/snapshots.txt:
#   - whole OS:   snapper -c root rollback <n>  (then reboot)
#   - whole home: mount -o subvolid=5 <dev> /mnt; the read-only copy is /mnt/kyberos-rollback/home-<stamp>
#   - unbootable splash: the saved initramfs/initrd image in the snapshot dir can be copied back to /boot
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run as root" >&2; exit 1; }
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/distro.sh"
SNAP=$(readlink -f "/var/lib/kyberos-rollback/${1:-pre-kyberos}")
[ -f "$SNAP/system.tar.zst" ] || { echo "no system snapshot at $SNAP" >&2; exit 1; }
TAROPTS=(--xattrs --acls); command -v restorecon >/dev/null && TAROPTS+=(--selinux)
say() { printf '\033[1;35m[restore-system]\033[0m %s\n' "$*"; }
(cd "$SNAP" && sha256sum --quiet -c SHA256SUMS) || { echo "snapshot checksum mismatch, stopping" >&2; exit 1; }

# remove KyberOS's system files (the splash is rebuilt once, below, from the snapshot's theme)
rm -f /var/lib/kyberos/plymouth-previous
"$HERE/uninstall-system.sh"

ASIDE=$SNAP/replaced-$(date +%Y%m%d-%H%M%S)
say "restoring greeter config (current copies -> $ASIDE)"
for p in /etc/plasmalogin.conf.d /var/lib/plasmalogin/.config /etc/plymouth /etc/sddm.conf.d; do
    [ -e "$p" ] || continue
    mkdir -p "$ASIDE$(dirname "$p")"
    mv "$p" "$ASIDE$p"
done
want=()
in_tar=$(tar --zstd -tf "$SNAP/system.tar.zst" | sed 's#/$##')
for p in etc/plasmalogin.conf.d var/lib/plasmalogin/.config etc/plymouth etc/sddm.conf.d; do
    grep -qxF "$p" <<<"$in_tar" && want+=("$p")
done
[ ${#want[@]} -gt 0 ] && tar --zstd -xpf "$SNAP/system.tar.zst" "${TAROPTS[@]}" -C / "${want[@]}"
[ -d /var/lib/plasmalogin ] && mkdir -p /etc/plasmalogin.conf.d
command -v restorecon >/dev/null && restorecon -R /etc/plasmalogin.conf.d /var/lib/plasmalogin /etc/plymouth /etc/sddm.conf.d 2>/dev/null || true

theme=$(cat "$SNAP/plymouth-theme" 2>/dev/null || true)
if [ -n "$theme" ]; then
    # a theme that isn't on disk any more (e.g. an older KyberOS) comes back from the archive
    if [ ! -d "/usr/share/plymouth/themes/$theme" ] && grep -qxF "usr/share/plymouth/themes/$theme" <<<"$in_tar"; then
        tar --zstd -xpf "$SNAP/system.tar.zst" "${TAROPTS[@]}" -C / "usr/share/plymouth/themes/$theme"
    fi
    say "boot splash -> '$theme' (rebuilding initramfs)"
    kyb_plymouth_set "$theme" || { say "'$theme' failed, using the distro default"; kyb_plymouth_set bgrt || kyb_plymouth_set spinner || true; }
fi
say "done. Packages KyberOS added (safe to keep; remove with your package manager if wanted):"
old=$SNAP/packages.txt; [ -f "$old" ] || old=$SNAP/rpm-qa.txt     # snapshots before 2026-10-15 evening
[ -f "$old" ] && comm -13 "$old" <(kyb_packages) | sed 's/^/  /' || true
