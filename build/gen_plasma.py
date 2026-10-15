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


def shadow_frame(prefix="shadow", size=22, alpha=0.5):
    """Soft drop shadow as nine pieces with gradients (Plasma reads shadow-*)."""
    c = size
    defs = (f'<radialGradient id="{prefix}-rg" cx="1" cy="1" r="1" gradientUnits="objectBoundingBox">'
            f'<stop offset="0" stop-color="#000" stop-opacity="{alpha}"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>'
            f'<linearGradient id="{prefix}-lg" x1="1" y1="0" x2="0" y2="0">'
            f'<stop offset="0" stop-color="#000" stop-opacity="{alpha}"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>')
    pieces = []
    ox, oy = 420, 0
    corner_rot = {"topleft": 0, "topright": 90, "bottomright": 180, "bottomleft": 270}
    for i, (name, rot) in enumerate(corner_rot.items()):
        x, y = ox + i * (c + 4), oy
        pieces.append(f'<g id="{prefix}-{name}"><rect x="{x}" y="{y}" width="{c}" height="{c}" fill="url(#{prefix}-rg)" '
                      f'transform="rotate({rot} {x + c / 2} {y + c / 2})"/></g>')
    edge_rot = {"left": 0, "top": 90, "right": 180, "bottom": 270}
    for i, (name, rot) in enumerate(edge_rot.items()):
        x, y = ox + i * (c + 4), oy + c + 6
        pieces.append(f'<g id="{prefix}-{name}"><rect x="{x}" y="{y}" width="{c}" height="{c}" fill="url(#{prefix}-lg)" '
                      f'transform="rotate({rot} {x + c / 2} {y + c / 2})"/></g>')
    pieces.append(f'<rect id="{prefix}-center" x="{ox}" y="{oy + 2 * c + 12}" width="4" height="4" style="fill:#000;fill-opacity:0"/>')
    return f"<defs>{defs}</defs>" + "".join(pieces)


def single(eid, x, y, w, h, body):
    return f'<g id="{eid}" transform="translate({x} {y})"><rect width="{w}" height="{h}" style="fill:#000;fill-opacity:0.004"/>{body}</g>'


def extras_slider():
    plate = lambda edge, fill, line: (f'<path d="M 3 5 L 6 2 H 18 V 15 L 15 18 H 3 Z" style="fill:{fill};stroke:{edge};stroke-width:1.5"/>'
                                      f'<rect x="9.25" y="5" width="1.5" height="10" {line}/>')
    hl = 'class="ColorScheme-Highlight" style="fill:currentColor"'
    parts = []
    for i, orient in enumerate(("horizontal", "vertical")):
        y = 80 + i * 30
        rot = "" if orient == "horizontal" else ' transform="rotate(90 10 10)"'
        parts.append(single(f"{orient}-slider-handle", 300, y, 20, 20, f'<g{rot}>{plate(BEVEL, STEEL, hl)}</g>'))
        parts.append(single(f"{orient}-slider-hover", 330, y, 20, 20, f'<g{rot}><path d="M 3 5 L 6 2 H 18 V 15 L 15 18 H 3 Z" class="ColorScheme-Highlight" style="fill:none;stroke:currentColor;stroke-width:1.5"/></g>'))
        parts.append(single(f"{orient}-slider-focus", 360, y, 20, 20, f'<g{rot}><path d="M 3 5 L 6 2 H 18 V 15 L 15 18 H 3 Z" class="ColorScheme-Highlight" style="fill:none;stroke:currentColor;stroke-width:2"/></g>'))
        parts.append(single(f"{orient}-slider-shadow", 390, y, 20, 20, ""))
    parts.append(f'<rect id="hint-handle-size" x="420" y="80" width="20" height="20" style="fill:#000;fill-opacity:0.004"/>')
    return "".join(parts)


def extras_checkmarks():
    hl = 'class="ColorScheme-Highlight" style="fill:none;stroke:currentColor;stroke-width:2.5;stroke-linecap:square"'
    return (single("checkbox", 300, 0, 16, 16, f'<path d="M 3.5 8.5 L 6.5 11.5 L 12.5 4.5" {hl}/>')
            + single("radiobutton", 330, 0, 16, 16, '<path d="M 8 3 L 13 8 L 8 13 L 3 8 Z" class="ColorScheme-Highlight" style="fill:currentColor"/>'))


def extras_radio():
    d = "M 10 1.5 L 18.5 10 L 10 18.5 L 1.5 10 Z"
    return (single("normal", 300, 0, 20, 20, f'<path d="{d}" style="fill:{VOID};stroke:{EDGE};stroke-width:1.5"/>')
            + single("hover", 330, 0, 20, 20, f'<path d="{d}" class="ColorScheme-Highlight" style="fill:none;stroke:currentColor;stroke-width:1.5"/>')
            + single("focus", 360, 0, 20, 20, f'<path d="{d}" class="ColorScheme-Highlight" style="fill:none;stroke:currentColor;stroke-width:2"/>')
            + single("checked", 390, 0, 20, 20, '<path d="M 10 5 L 15 10 L 10 15 L 5 10 Z" class="ColorScheme-Highlight" style="fill:currentColor"/>')
            + single("symbol", 420, 0, 20, 20, '<path d="M 10 5 L 15 10 L 10 15 L 5 10 Z" class="ColorScheme-Highlight" style="fill:currentColor"/>')
            + single("shadow", 450, 0, 20, 20, "")
            + '<rect id="hint-size" x="480" y="0" width="20" height="20" style="fill:#000;fill-opacity:0.004"/>')


def extras_switch():
    h = '<path d="M 2 4 L 5 1 H 18 V 16 L 15 19 H 2 Z" style="fill:{f};stroke:{e};stroke-width:1.5"/>'
    return (single("handle", 300, 120, 20, 20, h.format(f=TEXT, e=BEVEL))
            + single("handle-hover", 330, 120, 20, 20, '<path d="M 2 4 L 5 1 H 18 V 16 L 15 19 H 2 Z" class="ColorScheme-Highlight" style="fill:none;stroke:currentColor;stroke-width:1.5"/>')
            + single("handle-focus", 360, 120, 20, 20, '<path d="M 2 4 L 5 1 H 18 V 16 L 15 19 H 2 Z" class="ColorScheme-Highlight" style="fill:none;stroke:currentColor;stroke-width:2"/>')
            + single("handle-pressed", 390, 120, 20, 20, h.format(f=DIM, e=BEVEL))
            + single("handle-shadow", 420, 120, 20, 20, "")
            + '<rect id="hint-bar-size" x="450" y="120" width="12" height="12" style="fill:#000;fill-opacity:0.004"/>')


def generate(out):
    base = out / "plasma" / "desktoptheme" / "KyberOS"
    base.mkdir(parents=True, exist_ok=True)

    surface = dict(corner=10, chamfer=8, fill=(BG, 0.96), border=BEVEL, diag=HL)

    # Popups, notifications, OSDs, desktop widgets, tooltips (+ soft shadows).
    write(base, "dialogs/background.svg", [Frame(**surface)], extra=shadow_frame(), extra_size=(560, 70))
    # translucent variants are used when blur is available: glassy holo-console
    write(base, "translucent/dialogs/background.svg", [Frame(**{**surface, "fill": (BG, 0.8)})], extra=shadow_frame(), extra_size=(560, 70))
    write(base, "widgets/background.svg", [Frame(**{**surface, "fill": (BG, 0.88)})])
    write(base, "widgets/tooltip.svg", [Frame(corner=6, chamfer=5, fill=(VOID, 0.97), border=BEVEL, diag=HL)])

    # Panels: chamfered body with an accent seam; Plasma hides borders on screen edges.
    for rel, op in (("widgets/panel-background.svg", 0.94), ("translucent/widgets/panel-background.svg", 0.82)):
        write(base, rel, [
            Frame(corner=8, chamfer=6, fill=(BG, op), border=BEVEL, diag=HL),
            Frame(prefix="floating", corner=8, chamfer=6, fill=(BG, op), border=EDGE, diag=HL),
        ], extra=shadow_frame(size=18, alpha=0.45), extra_size=(560, 70))

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

    # sliders, scrollbars, check/radio, switch, tabs inside Plasma popups
    write(base, "widgets/slider.svg", [
        Frame(prefix="groove", corner=3, fill=(VOID, 0.9), border=BEVEL),
        Frame(prefix="groove-highlight", corner=3, fill=(HL, 0.9), border=HL),
    ], extra=extras_slider(), extra_size=(460, 140))
    write(base, "widgets/scrollbar.svg", [
        Frame(prefix="background-vertical", corner=3, fill=(VOID, 0.45)),
        Frame(prefix="background-horizontal", corner=3, fill=(VOID, 0.45)),
        Frame(prefix="slider", corner=3, fill=(EDGE, 0.9)),
        Frame(prefix="mouseover-slider", corner=3, fill=(HL, 0.9)),
    ], extra='<rect id="hint-scrollbar-size" x="300" y="0" width="10" height="10" style="fill:#000;fill-opacity:0.004"/>', extra_size=(320, 0))
    write(base, "widgets/checkmarks.svg", [], extra=extras_checkmarks(), extra_size=(360, 20), stretch=False)
    write(base, "widgets/radiobutton.svg", [], extra=extras_radio(), extra_size=(510, 24), stretch=False)
    write(base, "widgets/switch.svg", [
        Frame(prefix="inactive", corner=4, chamfer=3, fill=(VOID, 0.9), border=BEVEL),
        Frame(prefix="active", corner=4, chamfer=3, fill=(HL, 0.55), border=HL, diag=HL),
    ], extra=extras_switch(), extra_size=(470, 150))
    write(base, "widgets/tabbar.svg", [
        Frame(prefix="north-active-tab", corner=4, fill=(HL, 0.12), bars={"bottom": (HL, 3)}),
        Frame(prefix="south-active-tab", corner=4, fill=(HL, 0.12), bars={"top": (HL, 3)}),
        Frame(prefix="east-active-tab", corner=4, fill=(HL, 0.18), border=(HL, 0.6)),
        Frame(prefix="west-active-tab", corner=4, fill=(HL, 0.18), border=(HL, 0.6)),
    ])

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
