#!/usr/bin/env python3
"""Generate every KyberOS asset into dist/.

dist/ mirrors the install layout under ~/.local/share (plus plymouth/ for the
system splash). Hand-written packages in src/ are copied first, then the
generators add colours, SVG themes, images, cursors and sounds.
Rasterising needs rsvg-convert; cursors also need xcursorgen.
usage: build.py [outdir] [generator ...]
"""
import importlib
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(HERE))

GENERATORS = [
    "gen_colors",
    "gen_plasma",
    "gen_aurorae",
    "gen_konsole",
    "gen_wallpaper",
    "gen_icons",
    "gen_cursors",
    "gen_sounds",
    "gen_plymouth",
    "gen_lnf",
    "gen_kvantum",
]

# src/ subtrees copied verbatim into dist/ (plymouth is handled by its generator)
STATIC = ["plasma", "kwin"]


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "dist"
    only = set(sys.argv[2:])
    if out.exists() and not only:
        shutil.rmtree(out)
    out.mkdir(parents=True, exist_ok=True)
    if not only:
        for sub in STATIC:
            shutil.copytree(ROOT / "src" / sub, out / sub, dirs_exist_ok=True)
        print("  copied src/")
    for name in GENERATORS:
        if only and name not in only:
            continue
        importlib.import_module(name).generate(out)
        print(f"  built {name}")
    print(f"KyberOS assets in {out}")


if __name__ == "__main__":
    main()
