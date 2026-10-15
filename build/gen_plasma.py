"""Plasma style (desktoptheme) 'KyberOS'.

Surfaces are cold steel with a bevel line; chamfered top-left/bottom-right
corners carry an accent diagonal (ColorScheme-Highlight), so the whole style
follows whichever kyber crystal colour scheme is active.
"""
import json
from palette import *
from svgframe import Frame, document

HL = "ColorScheme-Highlight"
BG = "ColorScheme-Background"
COLORS = dict(text=TEXT, bg=PANEL, view=DEEP, button=STEEL, accent=CRYSTALS[DEFAULT_CRYSTAL],
              amber=AMBER, alert=ALERT, ok=OK)


def write(base, rel, frames, **kw):
    p = base / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(document(frames, COLORS, **kw))


def busy_reticle():
    """Targeting reticle; Plasma spins the 'busywidget' element."""
    c, r = 32, 26
    ticks = []
    for i in range(12):
        ticks.append(f'<rect x="{c - 1}" y="{c - r - 4}" width="2" height="{7 if i % 3 == 0 else 4}" '
                     f'transform="rotate({i * 30} {c} {c})" class="ColorScheme-Text" style="fill:currentColor;fill-opacity:0.55"/>')
    arc = (f'<path d="M {c} {c - r} A {r} {r} 0 0 1 {c + r} {c}" class="{HL}" '
           f'style="fill:none;stroke:currentColor;stroke-width:3;stroke-linecap:butt"/>')
    arc2 = (f'<path d="M {c} {c + r} A {r} {r} 0 0 1 {c - r} {c}" class="{HL}" '
            f'style="fill:none;stroke:currentColor;stroke-width:3;stroke-opacity:0.45"/>')
    core = (f'<path d="M {c - 6} {c} H {c + 6} M {c} {c - 6} V {c + 6}" class="ColorScheme-Text" '
            f'style="fill:none;stroke:currentColor;stroke-width:1.5;stroke-opacity:0.8"/>')
    return f'<g id="busywidget" transform="translate(300 0)"><rect width="64" height="64" style="fill:#000;fill-opacity:0.004"/>{"".join(ticks)}{arc}{arc2}{core}</g>'


def generate(out):
    base = out / "plasma" / "desktoptheme" / "KyberOS"
    base.mkdir(parents=True, exist_ok=True)

    surface = dict(corner=10, chamfer=8, fill=(BG, 0.96), border=BEVEL, diag=HL)

    # Popups, notifications, OSDs, desktop widgets, tooltips.
    write(base, "dialogs/background.svg", [Frame(**surface)])
    write(base, "widgets/background.svg", [Frame(**{**surface, "fill": (BG, 0.88)})])
    write(base, "widgets/tooltip.svg", [Frame(corner=6, chamfer=5, fill=(VOID, 0.97), border=BEVEL, diag=HL)])

    # Panels: chamfered body with an accent seam; Plasma hides borders on screen edges.
    write(base, "widgets/panel-background.svg", [
        Frame(corner=8, chamfer=6, fill=(BG, 0.94), border=BEVEL, diag=HL),
        Frame(prefix="floating", corner=8, chamfer=6, fill=(BG, 0.94), border=EDGE, diag=HL),
    ])

    # Task manager buttons: a lit 'saber' bar under the active task.
    tasks = dict(corner=5, chamfer=0, edge=4)
    write(base, "widgets/tasks.svg", [
        Frame(prefix="normal", **tasks, fill=("#000000", 0.001)),
        Frame(prefix="hover", **tasks, fill=(STEEL, 0.75), border=BEVEL, bars={"bottom": ((HL), 1)}),
        Frame(prefix="focus", **tasks, fill=(RAISED, 0.85), border=BEVEL, bars={"bottom": (HL, 3)}),
        Frame(prefix="attention", **tasks, fill=(mix(PANEL, AMBER, 0.18), 0.9), border=AMBER, bars={"bottom": (AMBER, 3)}),
        Frame(prefix="minimized", **tasks, fill=("#000000", 0.001), bars={"bottom": (EDGE, 1)}),
    ])

    # List / menu highlights (Kickoff, tray popups...).
    view = dict(corner=5, chamfer=4, chamfered=("topleft", "bottomright"))
    write(base, "widgets/viewitem.svg", [
        Frame(prefix="normal", **view, fill=("#000000", 0.001)),
        Frame(prefix="hover", **view, fill=(HL, 0.14), border=(HL, 0.35), diag=HL),
        Frame(prefix="selected", **view, fill=(HL, 0.26), border=(HL, 0.6), diag=HL),
        Frame(prefix="selected+hover", **view, fill=(HL, 0.34), border=HL, diag=HL),
    ])

    # Buttons and text fields in Plasma components.
    btn = dict(corner=6, chamfer=5)
    write(base, "widgets/button.svg", [
        Frame(prefix="normal", **btn, fill=(STEEL, 1), border=BEVEL),
        Frame(prefix="hover", **btn, fill=(RAISED, 1), border=(HL, 0.7), diag=HL),
        Frame(prefix="pressed", **btn, fill=(HL, 0.3), border=HL, diag=HL),
        Frame(prefix="focus", **btn, fill=(STEEL, 1), border=HL, diag=HL),
        Frame(prefix="toolbutton-hover", **btn, fill=(HL, 0.12), border=(HL, 0.45), diag=HL),
        Frame(prefix="toolbutton-pressed", **btn, fill=(HL, 0.28), border=HL, diag=HL),
        Frame(prefix="toolbutton-focus", **btn, fill=("#000000", 0.001), border=HL),
    ])
    write(base, "widgets/lineedit.svg", [
        Frame(prefix="base", corner=5, chamfer=0, fill=(VOID, 0.9), border=BEVEL),
        Frame(prefix="hover", corner=5, chamfer=0, fill=("#000000", 0.001), border=(HL, 0.5)),
        Frame(prefix="focus", corner=5, chamfer=0, fill=("#000000", 0.001), border=HL, bars={"bottom": (HL, 2)}),
    ])
    write(base, "widgets/frame.svg", [
        Frame(prefix="plain", corner=4, fill=("#000000", 0.001), border=BEVEL),
        Frame(prefix="raised", corner=6, chamfer=5, fill=(STEEL, 0.9), border=BEVEL, diag=HL),
        Frame(prefix="sunken", corner=4, fill=(VOID, 0.7), border=BEVEL),
    ])
    write(base, "widgets/plasmoidheading.svg", [
        Frame(prefix="header", corner=8, chamfer=6, chamfered=("topleft",), fill=(STEEL, 0.9), border=BEVEL, diag=HL, bars={"bottom": ((HL, 0.6), 1)}),
        Frame(prefix="footer", corner=8, chamfer=6, chamfered=("bottomright",), fill=(STEEL, 0.9), border=BEVEL, diag=HL),
    ])

    # Progress and meters drawn as a lightsaber blade: white-hot core, coloured edge.
    for orient in ("horizontal", "vertical"):
        write(base, f"widgets/bar_meter_{orient}.svg", [
            Frame(prefix="bar-inactive", corner=3, fill=(VOID, 0.85), border=BEVEL),
            Frame(prefix="bar-active", corner=3, fill=("#f2fbff", 0.95), border=HL, border_w=1.5),
        ])

    write(base, "widgets/busywidget.svg", [], extra=busy_reticle(), extra_size=(370, 70), stretch=False)

    meta = {
        "KPlugin": {
            "Id": "KyberOS",
            "Name": "KyberOS",
            "Description": "Imperial console Plasma style with kyber crystal accents",
            "Authors": [{"Name": "KyberOS"}],
            "License": "GPL-3.0-or-later",
            "Version": "0.1",
            "Category": "",
        },
        "X-Plasma-API-Minimum-Version": "6.0",
    }
    (base / "metadata.json").write_text(json.dumps(meta, indent=2))
    (base / "plasmarc").write_text("[ContrastEffect]\nenabled=true\ncontrast=0.4\nintensity=1.6\nsaturation=1.4\n\n[AdaptiveTransparency]\nenabled=false\n")
