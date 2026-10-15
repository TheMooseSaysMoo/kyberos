# Rolling back KyberOS

A rollout (`sudo system/rollout.sh`, then `./install.sh`) is preceded by snapshots that
put the machine back exactly as it was. Take them with:

```
tools/rollback/snapshot.sh            # desktop user, no sudo  -> ~/KyberOS-Rollback/<stamp>/
sudo system/snapshot-system.sh        # (rollout.sh runs this) -> /var/lib/kyberos-rollback/<stamp>/
```

The first snapshot of each kind is linked as `pre-kyberos`. Later snapshots never move that link.

## Restoring: from lightest to heaviest

| What | Command | Restores |
|---|---|---|
| Desktop only | `~/kyberos/tools/rollback/restore.sh` | Theme, panels, effects, Kvantum, GTK and fonts as they were. Other apps' settings are kept. |
| Desktop + boot/login | `~/kyberos/tools/rollback/restore.sh --system` | Adds the old boot splash (rebuilds the initramfs) and the login screen config. |
| All app configs | `~/kyberos/tools/rollback/restore.sh --full` | Everything in the archive: all of `~/.config` and most of `~/.local/share`. This overwrites app changes made since the snapshot. |
| Whole OS | `sudo snapper -c root rollback <n>` then reboot | Everything under `/`. The number is in `/var/lib/kyberos-rollback/pre-kyberos/snapshots.txt`. |
| Whole home | `sudo mount -o subvolid=5 <dev> /mnt`, copy from `/mnt/kyberos-rollback/home-<stamp>` | A read-only copy of `/home` from just before the rollout. |

`restore.sh` and `restore-system.sh` move whatever they replace into `<snapshot>/replaced-<time>/`, so a restore can be undone too. Log out and back in afterwards.

If the boot splash ever stops a boot, pick the previous kernel in GRUB, or boot with `plymouth.enable=0`. The pre-rollout initramfs is saved as `/var/lib/kyberos-rollback/pre-kyberos/initramfs-<kver>.img`.

The packages the rollout added (kvantum, librsvg2-tools, xcursorgen, plymouth-plugin-script) are harmless to keep. `restore-system.sh` lists them.

## What a snapshot contains
- **`user.tar.zst`**:
  - `~/.config` (minus app caches), `~/.local/share`, `~/.local/bin`, `~/.local/state` and dotfiles.
  - Large app data is left out (Steam, Wine prefixes, Flatpak apps, PWAs, Trash); `state/excluded.txt` lists what was skipped.
  - None of it is touched by KyberOS.
- **`state/`**: a readable record of the old setup.
  - Files: `theme.txt`, `plasma-layout.json` (panels, widgets, wallpapers), `screens.txt`, `appletsrc.ini`, `user-units.txt`, `plasma-packages.txt`.
- **System side**: `system.tar.zst` holds:
  - `/etc/plymouth` and the current splash theme;
  - the greeter config, `/var/lib/plasmalogin`, `/etc/default/grub` and `/usr/local/share`.
  
  It also keeps the initramfs, the kernel cmdline, `rpm -qa`, and the btrfs snapshot references.
