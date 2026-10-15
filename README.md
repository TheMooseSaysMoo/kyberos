# KyberOS

An Imperial-console themed KDE Plasma 6 desktop, inspired by the screens on Star Wars
ships and bases: cold steel, chamfered panels, kyber-crystal accents, blast doors and
hyperspace. All artwork, sounds and code here are original (no film assets, logos or audio).

Target: Fedora 44 KDE, Plasma 6.7.

```bash
./install.sh                    # build + install for this user, keep your panels
./install.sh --layout           # also replace panels with the KyberOS strip + dock (pinned apps kept)
./install.sh --crystal red      # blue | green | red | purple | yellow | white
./install.sh --system           # also boot splash + login greeter (sudo)
kyberos-crystal green           # re-tune everything to another crystal later
./uninstall.sh [--system]       # restore the backed-up settings
```

For a machine you care about, snapshot first and roll out in two halves:

```bash
tools/rollback/snapshot.sh      # whole desktop -> ~/KyberOS-Rollback/<stamp>
sudo system/rollout.sh          # system snapshot (snapper + /home), packages, boot + login theme
./install.sh --layout           # the desktop
tools/rollback/restore.sh [--system]   # put it all back, see docs/ROLLBACK.md
```

See `docs/COMPONENTS.md` for what each piece is and where it is generated.
