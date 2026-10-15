"""Plymouth boot splash 'kyberos': hyperspace starfield + saber progress bar.

Images are generated here; the animation lives in src/plymouth/kyberos/kyberos.script.
"""
import os
import shutil
from pathlib import Path
from palette import *
from glyphs import wordmark, crystal as crystal_svg
import raster

SRC = Path(__file__).resolve().parent.parent / "src" / "plymouth" / "kyberos"


def svg(w, h, body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>'


def streak(length, a):
    h = 4
    return svg(length + 4, h, f'<defs><linearGradient id="g" x1="0" x2="1"><stop offset="0" stop-color="{a}" stop-opacity="0"/>'
                              f'<stop offset="0.7" stop-color="{mix(a, "#ffffff", 0.5)}" stop-opacity="0.8"/><stop offset="1" stop-color="#ffffff"/></linearGradient></defs>'
                              f'<rect x="2" y="1" width="{length}" height="2" rx="1" fill="url(#g)"/>')


def generate(out):
    a = CRYSTALS[os.environ.get("KYBEROS_CRYSTAL", DEFAULT_CRYSTAL)]
    d = out / "plymouth" / "kyberos"
    d.mkdir(parents=True, exist_ok=True)
    for f in SRC.iterdir():
        shutil.copy(f, d / f.name)
    images = {
        "logo": svg(1000, 200, crystal_svg(70, 100, 150, a) + wordmark(560, 100, 9.0, TEXT, a)),
        "streak0": streak(6, a),
        "streak1": streak(22, a),
        "streak2": streak(60, a),
        "streak3": streak(150, a),
        "hilt": svg(84, 20, f'<rect x="0" y="5" width="70" height="10" fill="#9aa6b5"/><rect x="6" y="3" width="6" height="14" fill="{BEVEL}"/>'
                            f'<rect x="22" y="4" width="3" height="12" fill="{EDGE}"/><rect x="28" y="4" width="3" height="12" fill="{EDGE}"/>'
                            f'<rect x="40" y="7" width="12" height="6" fill="{ALERT}"/><rect x="64" y="2" width="20" height="16" fill="#c5ced8"/>'),
        "blade": svg(400, 20, f'<defs><linearGradient id="v" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{a}" stop-opacity="0"/>'
                              f'<stop offset="0.3" stop-color="{a}" stop-opacity="0.9"/><stop offset="0.5" stop-color="#ffffff"/>'
                              f'<stop offset="0.7" stop-color="{a}" stop-opacity="0.9"/><stop offset="1" stop-color="{a}" stop-opacity="0"/></linearGradient></defs>'
                              f'<rect x="0" y="2" width="400" height="16" fill="url(#v)"/>'),
        "entry": svg(420, 44, f'<path d="M 1 9 L 9 1 H 419 V 35 L 411 43 H 1 Z" fill="{VOID}" fill-opacity="0.9" stroke="{a}" stroke-width="2"/>'),
        "bullet": svg(14, 14, f'<polygon points="7,0 14,7 7,14 0,7" fill="{a}"/>'),
    }
    for name, body in images.items():
        src = d / f"{name}.svg"
        src.write_text(body)
        if raster.png(src, d / f"{name}.png"):
            src.unlink()
