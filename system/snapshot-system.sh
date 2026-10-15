#!/usr/bin/env bash
# Snapshot the system side BEFORE KyberOS goes on (run as root). Undo with
# system/restore-system.sh, or roll the whole machine back with the btrfs snapshots.
#
#   /var/lib/kyberos-rollback/<stamp>/
#     system.tar.zst      /etc/plymouth, /etc/plasmalogin.conf*, /var/lib/plasmalogin,
#                         /etc/default/grub, /usr/local/share, /etc/sddm*
#     initramfs-<kver>.img  copy of the current initramfs (KyberOS's Plymouth step rebuilds it)
#     plymouth-theme, cmdline, packages.txt, display-manager, snapshots.txt
#   btrfs: snapper snapshot of / ("pre-KyberOS") and a read-only snapshot of the /home
#   subvolume at the top level of the filesystem (not inside /home, so home backups skip it)
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/../lib/distro.sh"
[ "$(id -u)" = 0 ] || { echo "run as root" >&2; exit 1; }
STAMP=${1:-$(date +%Y%m%d-%H%M%S)}
OUT=/var/lib/kyberos-rollback/$STAMP
mkdir -p "$OUT"; chmod 700 /var/lib/kyberos-rollback
say() { printf '\033[1;35m[snapshot-system]\033[0m %s\n' "$*"; }

say "archiving system config -> $OUT"
paths=()
theme=$(plymouth-set-default-theme 2>/dev/null || true)
[ -n "$theme" ] && [ -d "/usr/share/plymouth/themes/$theme" ] && paths+=("/usr/share/plymouth/themes/$theme")
for p in /etc/plymouth /etc/plasmalogin.conf /etc/plasmalogin.conf.d /var/lib/plasmalogin \
         /etc/default/grub /usr/local/share /etc/sddm.conf /etc/sddm.conf.d /var/lib/sddm/.config \
         /usr/share/plymouth/themes/default.plymouth /etc/mkinitcpio.conf /etc/initramfs-tools/conf.d /etc/lightdm; do
    [ -e "$p" ] && paths+=("$p")
done
TAROPTS=(--xattrs --acls); command -v restorecon >/dev/null && TAROPTS+=(--selinux)   # SELinux distros
tar --zstd -cpf "$OUT/system.tar.zst" "${TAROPTS[@]}" "${paths[@]}" 2>"$OUT/tar-warnings.txt" \
    || { echo "tar failed, see $OUT/tar-warnings.txt" >&2; exit 1; }
kver=$(uname -r)
# Fedora: initramfs-<kver>.img, Debian: initrd.img-<kver>, Arch: initramfs-linux*.img
for f in "/boot/initramfs-$kver.img" "/boot/initrd.img-$kver" /boot/initramfs-linux*.img; do
    [ -f "$f" ] && cp -a "$f" "$OUT/"
done
echo "$kver" > "$OUT/kernel"
echo "$theme" > "$OUT/plymouth-theme"
cat /proc/cmdline > "$OUT/cmdline"
kyb_packages > "$OUT/packages.txt"
kyb_dm > "$OUT/display-manager"

# ---- whole-machine snapshots ----
: > "$OUT/snapshots.txt"
if command -v snapper >/dev/null && snapper -c root list >/dev/null 2>&1; then
    n=$(snapper -c root create --type single --cleanup-algorithm '' --print-number \
        --description "pre-KyberOS $STAMP")
    echo "root: snapper -c root #$n (/.snapshots/$n/snapshot)" | tee -a "$OUT/snapshots.txt"
fi
src=$(findmnt -no SOURCE /home | sed 's/\[.*//')
if [ "$(findmnt -no FSTYPE /home)" = btrfs ]; then
    top=$(mktemp -d)
    if mount -o subvolid=5 "$src" "$top"; then
        homesub=$(findmnt -no SOURCE /home | sed -n 's/.*\[\/\?\(.*\)\]/\1/p')
        mkdir -p "$top/kyberos-rollback"
        btrfs subvolume snapshot -r "$top/$homesub" "$top/kyberos-rollback/home-$STAMP" >/dev/null \
            && echo "home: read-only btrfs snapshot <top-level>/kyberos-rollback/home-$STAMP (mount -o subvolid=5 $src /mnt)" \
            | tee -a "$OUT/snapshots.txt"
        umount "$top"
    fi
    rmdir "$top"
fi
(cd "$OUT" && sha256sum system.tar.zst initramfs-*.img initrd.img-* 2>/dev/null > SHA256SUMS)
[ -e /var/lib/kyberos-rollback/pre-kyberos ] || ln -s "$STAMP" /var/lib/kyberos-rollback/pre-kyberos
say "done: $OUT"
