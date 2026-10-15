"""Xcursor themes 'KyberOS-<Crystal>' (needs rsvg-convert + xcursorgen)."""
import math
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from palette import *
import raster

SIZES = [24, 32, 48, 64]
NOMINAL = 32
OUT_STROKE = f'stroke:{VOID};stroke-opacity:0.9;stroke-linejoin:miter'

ARROW = [(3, 2), (3, 24), (8.6, 18.6), (12.8, 28), (16.4, 26.4), (12.2, 17.2), (19.8, 17.2)]


def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">{body}</svg>'


def pts(p):
    return " ".join(f"{x},{y}" for x, y in p)


def arrow(a):
    return (f'<polygon points="{pts(ARROW)}" style="fill:none;{OUT_STROKE};stroke-width:3.2"/>'
            f'<polygon points="{pts(ARROW)}" style="fill:{STEEL};stroke:{a};stroke-width:1.4;stroke-linejoin:miter"/>'
            f'<path d="M 4.6 5.5 V 19.5" style="stroke:#f4fbff;stroke-width:1.2;stroke-opacity:0.85"/>')


def badge(a, inner):
    return (f'<polygon points="24,17 30,23 24,29 18,23" style="fill:{VOID};stroke:{VOID};stroke-width:2.5"/>'
            f'<polygon points="24,17 30,23 24,29 18,23" style="fill:{STEEL};stroke:{a};stroke-width:1.3"/>{inner}')


def line(d, col, w=1.6):
    return (f'<path d="{d}" style="fill:none;{OUT_STROKE};stroke-width:{w + 1.8};stroke-linecap:square"/>'
            f'<path d="{d}" style="fill:none;stroke:{col};stroke-width:{w};stroke-linecap:square;stroke-linejoin:miter"/>')


def spinner(a, cx, cy, r, phase, w=2.4):
    out = [f'<circle cx="{cx}" cy="{cy}" r="{r + 1.6}" style="fill:{VOID};fill-opacity:0.75"/>']
    for i in range(6):
        a0 = math.radians(phase + i * 60 + 6)
        a1 = math.radians(phase + i * 60 + 46)
        op = 1.0 if i == 0 else (0.75 if i == 1 else 0.3)
        col = "#f4fbff" if i == 0 else a
        out.append(f'<path d="M {cx + r * math.cos(a0):.2f} {cy + r * math.sin(a0):.2f} A {r} {r} 0 0 1 '
                   f'{cx + r * math.cos(a1):.2f} {cy + r * math.sin(a1):.2f}" style="fill:none;stroke:{col};stroke-opacity:{op};stroke-width:{w}"/>')
    return "".join(out)


def double_arrow(a, angle):
    d = "M 6 16 H 26 M 10 12 L 6 16 L 10 20 M 22 12 L 26 16 L 22 20"
    return f'<g transform="rotate({angle} 16 16)">{line(d, a, 1.8)}</g>'


def cursors(a):
    """name -> (list of frame svgs, hotspot at 32px)."""
    c = {}
    c["default"] = ([svg(arrow(a))], (3, 2))
    c["pointer"] = ([svg(arrow(a) + badge(a, f'<circle cx="24" cy="23" r="2" style="fill:{a}"/>'))], (3, 2))
    c["help"] = ([svg(arrow(a) + badge(a, f'<path d="M 22.2 21.4 Q 22.2 19.6 24 19.6 Q 25.8 19.6 25.8 21.2 Q 25.8 22.4 24 23.2 V 24.4" style="fill:none;stroke:{a};stroke-width:1.2"/><rect x="23.4" y="25.4" width="1.2" height="1.2" style="fill:{a}"/>'))], (3, 2))
    c["text"] = ([svg(line("M 12 6 H 20 M 16 6 V 26 M 12 26 H 20", "#f4fbff", 1.6))], (16, 16))
    c["crosshair"] = ([svg(line("M 16 3 V 10 M 16 22 V 29 M 3 16 H 10 M 22 16 H 29", "#f4fbff", 1.4)
                           + f'<circle cx="16" cy="16" r="7" style="fill:none;stroke:{VOID};stroke-width:3"/>'
                           + f'<circle cx="16" cy="16" r="7" style="fill:none;stroke:{a};stroke-width:1.4"/>'
                           + f'<rect x="15" y="15" width="2" height="2" style="fill:{ALERT}"/>')], (16, 16))
    c["not-allowed"] = ([svg(f'<circle cx="16" cy="16" r="10" style="fill:{VOID};fill-opacity:0.6;stroke:{VOID};stroke-width:4.5"/>'
                             f'<circle cx="16" cy="16" r="10" style="fill:none;stroke:{ALERT};stroke-width:2.6"/>'
                             f'<path d="M 9 9 L 23 23" style="stroke:{ALERT};stroke-width:2.6"/>')], (16, 16))
    c["wait"] = ([svg(spinner(a, 16, 16, 10, i * 30)) for i in range(12)], (16, 16))
    c["progress"] = ([svg(arrow(a) + spinner(a, 24, 24, 5.5, i * 30, 1.8)) for i in range(12)], (3, 2))
    c["move"] = ([svg(line("M 16 4 V 28 M 4 16 H 28 M 12 8 L 16 4 L 20 8 M 12 24 L 16 28 L 20 24 M 8 12 L 4 16 L 8 20 M 24 12 L 28 16 L 24 20", a, 1.6))], (16, 16))
    c["ew-resize"] = ([svg(double_arrow(a, 0))], (16, 16))
    c["ns-resize"] = ([svg(double_arrow(a, 90))], (16, 16))
    c["nwse-resize"] = ([svg(double_arrow(a, 45))], (16, 16))
    c["nesw-resize"] = ([svg(double_arrow(a, -45))], (16, 16))
    return c


ALIASES = {
    "default": ["left_ptr", "arrow", "top_left_arrow", "context-menu", "copy", "alias", "dnd-copy", "dnd-link",
                "dnd-none", "dnd-ask", "draft", "pencil", "zoom-in", "zoom-out", "right_ptr", "center_ptr", "x-cursor", "X_cursor"],
    "pointer": ["hand1", "hand2", "pointing_hand", "e29285e634086352946a0e7090d73106", "9d800788f1b08800ae810202380a0822", "link"],
    "help": ["question_arrow", "whats_this", "left_ptr_help", "5c6cd98b3f3ebcb1f9c7f1c204630408", "d9ce0ab605698f320427677b458ad60b"],
    "text": ["xterm", "ibeam", "vertical-text"],
    "crosshair": ["cross", "tcross", "cell", "color-picker", "plus"],
    "not-allowed": ["crossed_circle", "forbidden", "no-drop", "circle", "03b6e0fcb3499374a867c041f52298f0", "dnd-no-drop", "pirate"],
    "wait": ["watch"],
    "progress": ["left_ptr_watch", "half-busy", "00000000000000020006000e7e9ffc3f", "08e8e1c95fe2fc01f976f1e063a24ccd", "3ecb610c1bf2410f44200f48c40d3599"],
    "move": ["fleur", "all-scroll", "size_all", "grab", "grabbing", "openhand", "closedhand", "dnd-move",
             "4498f0e0c1937ffe01fd06f973665830", "9081237383d90e509aa00f00170e968f", "fcf21c00b30f7e3f83fe0dfd12e71cff"],
    "ew-resize": ["sb_h_double_arrow", "h_double_arrow", "col-resize", "size_hor", "left_side", "right_side", "e-resize",
                  "w-resize", "split_h", "14fef782d02440884392942c11205230", "028006030e0e7ebffc7f7070c0600140"],
    "ns-resize": ["sb_v_double_arrow", "v_double_arrow", "row-resize", "size_ver", "top_side", "bottom_side", "n-resize",
                  "s-resize", "split_v", "2870a09082c103050810ffdffffe0204", "00008160000006810000408080010102"],
    "nwse-resize": ["size_fdiag", "bd_double_arrow", "top_left_corner", "bottom_right_corner", "nw-resize", "se-resize",
                    "c7088f0f3e6c8088236ef8e1e3e70000"],
    "nesw-resize": ["size_bdiag", "fd_double_arrow", "top_right_corner", "bottom_left_corner", "ne-resize", "sw-resize",
                    "fcf1c3c7cd4491d801f1e1c78f100000"],
}


def generate(out):
    if not (raster.available() and shutil.which("xcursorgen")):
        print("    ! cursors skipped (need rsvg-convert + xcursorgen)")
        return
    for crystal, a in CRYSTALS.items():
        name = f"KyberOS-{crystal.capitalize()}"
        theme = out / "icons" / name
        cdir = theme / "cursors"
        cdir.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            for cname, (frames, (hx, hy)) in cursors(a).items():
                cfg = []
                for fi, frame in enumerate(frames):
                    src = tmp / f"{cname}-{fi}.svg"
                    src.write_text(frame)
                    for s in SIZES:
                        png = tmp / f"{cname}-{fi}-{s}.png"
                        raster.png(src, png, s, s)
                        k = s / NOMINAL
                        delay = " 55" if len(frames) > 1 else ""
                        cfg.append(f"{s} {round(hx * k)} {round(hy * k)} {png}{delay}")
                (tmp / f"{cname}.cfg").write_text("\n".join(cfg) + "\n")
                subprocess.run(["xcursorgen", str(tmp / f"{cname}.cfg"), str(cdir / cname)], check=True)
                for alias in ALIASES.get(cname, []):
                    link = cdir / alias
                    if not link.exists():
                        os.symlink(cname, link)
        (theme / "index.theme").write_text(f"[Icon Theme]\nName=KyberOS {crystal.capitalize()} Cursors\nComment=Imperial console cursors\nInherits=breeze_cursors\n")
