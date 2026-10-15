"""Aurorae window decoration, one theme per crystal (KyberOS-<Crystal>).

Titlebar: steel slab, chamfered top-left corner with an accent diagonal, and a
lit 'saber' line under the title of the active window.
"""
import math
from palette import *

B = 3                 # side/bottom border
TE_TOP, TITLE_H, TE_BOT = 3, 22, 3
T = TE_TOP + TITLE_H + TE_BOT
CW = 16               # top corner tile width
K = 11                # chamfer
E = 4                 # stretched tile length
BTN_W, BTN_H = 28, 22
SQ2 = math.sqrt(2) - 1


def poly(pts, fill, op=1):
    return f'<polygon points="{" ".join(f"{x:.2f},{y:.2f}" for x, y in pts)}" style="fill:{fill};fill-opacity:{op}"/>'


def sizer(x, y, w, h):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" style="fill:#000;fill-opacity:0.004"/>'


def tile(eid, x, y, w, h, shapes):
    body = sizer(x, y, w, h) + "".join(poly([(x + a, y + b) for a, b in pts], f, o) for pts, f, o in shapes)
    return f'<g id="{eid}">{body}</g>'


def decoration_set(prefix, oy, line, line_w, diag, bg, chamfer=True, borders=True):
    """All nine pieces for one decoration state, stacked at y offset oy."""
    out = []
    k = K if chamfer else 0
    bw = 1 if borders else 0
    # top-left: chamfer + accent diagonal + saber line
    tl = []
    if k:
        tl.append(([(0, k), (k, 0), (CW, 0), (CW, T), (0, T)], bg, 1))
        if bw:
            d = SQ2
            tl.append(([(0, T), (0, k), (k, 0), (CW, 0), (CW, 1), (k + d, 1), (1, k + d), (1, T)], BEVEL, 1))
        dd = 2 * SQ2
        tl.append(([(0, k), (k, 0), (k + dd, 2), (2, k + dd)], diag, 1))
    else:
        tl.append(([(0, 0), (CW, 0), (CW, T), (0, T)], bg, 1))
    tl.append(([(0, T - line_w), (CW, T - line_w), (CW, T), (0, T)], line, 1))
    out.append(tile(f"{prefix}-topleft", 0, oy, CW, T, tl))

    top = [([(0, 0), (E, 0), (E, T), (0, T)], bg, 1)]
    if bw:
        top.append(([(0, 0), (E, 0), (E, 1), (0, 1)], BEVEL, 1))
    top.append(([(0, T - line_w), (E, T - line_w), (E, T), (0, T)], line, 1))
    out.append(tile(f"{prefix}-top", CW + 2, oy, E, T, top))

    tr = [([(0, 0), (CW, 0), (CW, T), (0, T)], bg, 1)]
    if bw:
        tr.append(([(0, 0), (CW, 0), (CW, T), (CW - 1, T), (CW - 1, 1), (0, 1)], BEVEL, 1))
    tr.append(([(0, T - line_w), (CW, T - line_w), (CW, T), (0, T)], line, 1))
    # three status 'LEDs' next to the buttons
    for i in range(3):
        tr.append(([(4 + i * 3.5, 4), (6 + i * 3.5, 4), (6 + i * 3.5, 6), (4 + i * 3.5, 6)], diag if i == 0 else EDGE, 1))
    out.append(tile(f"{prefix}-topright", CW + E + 4, oy, CW, T, tr))

    y2 = oy + T + 2
    side_w = max(B, 1)
    left = [([(0, 0), (side_w, 0), (side_w, E), (0, E)], bg, 1)]
    right = [([(0, 0), (side_w, 0), (side_w, E), (0, E)], bg, 1)]
    if bw:
        left.append(([(0, 0), (1, 0), (1, E), (0, E)], BEVEL, 1))
        right.append(([(side_w - 1, 0), (side_w, 0), (side_w, E), (side_w - 1, E)], BEVEL, 1))
    out.append(tile(f"{prefix}-left", 0, y2, side_w, E, left))
    out.append(tile(f"{prefix}-center", CW + 2, y2, E, E, [([(0, 0), (E, 0), (E, E), (0, E)], bg, 1)]))
    out.append(tile(f"{prefix}-right", CW + E + 4, y2, side_w, E, right))

    y3 = y2 + E + 2
    bl = [([(0, 0), (side_w, 0), (side_w, side_w), (0, side_w)], bg, 1)]
    bm = [([(0, 0), (E, 0), (E, side_w), (0, side_w)], bg, 1)]
    br = [([(0, 0), (side_w, 0), (side_w, side_w), (0, side_w)], bg, 1)]
    if bw:
        bl.append(([(0, 0), (1, 0), (1, side_w - 1), (side_w, side_w - 1), (side_w, side_w), (0, side_w)], BEVEL, 1))
        bm.append(([(0, side_w - 1), (E, side_w - 1), (E, side_w), (0, side_w)], BEVEL, 1))
        br.append(([(side_w - 1, 0), (side_w, 0), (side_w, side_w), (0, side_w), (0, side_w - 1), (side_w - 1, side_w - 1)], diag, 1))
    out.append(tile(f"{prefix}-bottomleft", 0, y3, side_w, side_w, bl))
    out.append(tile(f"{prefix}-bottom", CW + 2, y3, E, side_w, bm))
    out.append(tile(f"{prefix}-bottomright", CW + E + 4, y3, side_w, side_w, br))
    return "\n".join(out), y3 + side_w + 6


def decoration_svg(accent):
    parts, y = [], 0
    for prefix, line, lw, diag, bg, ch, bd in [
        ("decoration", accent, 2, accent, PANEL, True, True),
        ("decoration-inactive", BEVEL, 1, EDGE, VOID, True, True),
        ("decoration-maximized", accent, 2, accent, PANEL, False, False),
        ("decoration-maximized-inactive", BEVEL, 1, EDGE, VOID, False, False),
    ]:
        s, y = decoration_set(prefix, y, line, lw, diag, bg, ch, bd)
        parts.append(s)
    return svg_doc(60, y, "\n".join(parts))


def svg_doc(w, h, body):
    return f'<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n{body}\n</svg>\n'


# --- buttons -------------------------------------------------------------

def glyph(kind, col, w=1.6):
    cx, cy = BTN_W / 2, BTN_H / 2
    s = f'style="fill:none;stroke:{col};stroke-width:{w};stroke-linecap:square;stroke-linejoin:miter"'
    if kind == "close":
        return f'<path d="M {cx-4.5} {cy-4.5} L {cx+4.5} {cy+4.5} M {cx+4.5} {cy-4.5} L {cx-4.5} {cy+4.5}" {s}/>'
    if kind == "maximize":
        a = 5
        return (f'<path d="M {cx-a} {cy-a+3} V {cy-a} H {cx-a+3} M {cx+a-3} {cy-a} H {cx+a} V {cy-a+3} '
                f'M {cx+a} {cy+a-3} V {cy+a} H {cx+a-3} M {cx-a+3} {cy+a} H {cx-a} V {cy+a-3}" {s}/>')
    if kind == "restore":
        return (f'<path d="M {cx-5} {cy-2} H {cx+2} V {cy+5} H {cx-5} Z" {s}/>'
                f'<path d="M {cx-2} {cy-5} H {cx+5} V {cy+2}" {s}/>')
    if kind == "minimize":
        return f'<path d="M {cx-5} {cy+4} H {cx+5}" {s}/>'
    if kind == "alldesktops":
        return f'<path d="M {cx} {cy-5} L {cx+5} {cy} L {cx} {cy+5} L {cx-5} {cy} Z" {s}/>'
    if kind == "keepabove":
        return f'<path d="M {cx-5} {cy+2} L {cx} {cy-3} L {cx+5} {cy+2}" {s}/>'
    if kind == "keepbelow":
        return f'<path d="M {cx-5} {cy-2} L {cx} {cy+3} L {cx+5} {cy-2}" {s}/>'
    if kind == "shade":
        return f'<path d="M {cx-5} {cy-3} H {cx+5} M {cx-5} {cy+1} H {cx+5}" {s}/>'
    if kind == "help":
        return (f'<path d="M {cx-3} {cy-3} Q {cx-3} {cy-6} {cx} {cy-6} Q {cx+3} {cy-6} {cx+3} {cy-3} Q {cx+3} {cy-1} {cx} {cy} V {cy+2}" {s}/>'
                f'<rect x="{cx-1}" y="{cy+4}" width="2" height="2" style="fill:{col}"/>')
    return ""


def plate(fill, op, edge, edge_op=1):
    """Chamfered button plate."""
    k = 5
    pts = [(1, 1 + k), (1 + k, 1), (BTN_W - 1, 1), (BTN_W - 1, BTN_H - 1 - k), (BTN_W - 1 - k, BTN_H - 1), (1, BTN_H - 1)]
    p = " ".join(f"{x},{y}" for x, y in pts)
    return f'<polygon points="{p}" style="fill:{fill};fill-opacity:{op};stroke:{edge};stroke-opacity:{edge_op};stroke-width:1"/>'


def button_svg(kind, accent):
    danger = kind == "close"
    hot = ALERT if danger else accent
    states = [
        ("active", plate(STEEL, 0.0, BEVEL, 0.0), TEXT),
        ("hover", plate(hot, 0.85 if danger else 0.22, hot), "#ffffff" if danger else accent),
        ("pressed", plate(hot, 1 if danger else 0.4, hot), "#ffffff"),
        ("inactive", "", FAINT),
        ("hover-inactive", plate(hot, 0.6 if danger else 0.15, hot, 0.6), TEXT),
        ("pressed-inactive", plate(hot, 0.8 if danger else 0.3, hot), "#ffffff"),
        ("deactivated", "", FAINT),
        ("deactivated-inactive", "", FAINT),
        ("toggled", plate(accent, 0.3, accent), accent),
        ("toggled-inactive", plate(accent, 0.15, EDGE), DIM),
    ]
    parts = []
    for i, (state, plate_svg, col) in enumerate(states):
        x = i * (BTN_W + 4)
        parts.append(f'<g id="{state}-center" transform="translate({x} 0)">{sizer(0, 0, BTN_W, BTN_H)}{plate_svg}{glyph(kind, col)}</g>')
    return svg_doc(len(states) * (BTN_W + 4), BTN_H, "\n".join(parts))


def rc():
    return f"""[General]
ActiveTextColor={kde(TEXT)}
InactiveTextColor={kde(FAINT)}
TitleAlignment=Left
TitleVerticalAlignment=Center
Animation=160
UseTextShadow=false
Shadow=true
HaloActive=false
HaloInactive=false

[Layout]
BorderLeft={B}
BorderRight={B}
BorderBottom={B}
TitleEdgeTop={TE_TOP}
TitleEdgeBottom={TE_BOT}
TitleEdgeLeft={K + 4}
TitleEdgeRight=8
TitleEdgeTopMaximized=2
TitleEdgeBottomMaximized=2
TitleEdgeLeftMaximized=6
TitleEdgeRightMaximized=4
TitleBorderLeft=8
TitleBorderRight=8
TitleHeight={TITLE_H}
ButtonWidth={BTN_W}
ButtonHeight={BTN_H}
ButtonSpacing=2
ButtonMarginTop=0
ExplicitButtonSpacer=10
PaddingTop=0
PaddingBottom=0
PaddingLeft=0
PaddingRight=0
"""


def generate(out):
    root = out / "aurorae" / "themes"
    for crystal, accent in CRYSTALS.items():
        name = f"KyberOS-{crystal.capitalize()}"
        d = root / name
        d.mkdir(parents=True, exist_ok=True)
        (d / "decoration.svg").write_text(decoration_svg(accent))
        for kind in ("close", "maximize", "restore", "minimize", "alldesktops", "keepabove", "keepbelow", "shade", "help"):
            (d / f"{kind}.svg").write_text(button_svg(kind, accent))
        (d / f"{name}rc").write_text(rc())
        (d / "metadata.desktop").write_text(f"""[Desktop Entry]
Name=KyberOS {crystal.capitalize()} Crystal
Comment=Imperial console window decoration
X-KDE-PluginInfo-Name={name}
X-KDE-PluginInfo-Author=KyberOS
X-KDE-PluginInfo-Version=0.1
X-KDE-PluginInfo-License=GPL
X-Plasma-API=declarativeappletscript
X-KDE-ServiceTypes=KWin/Decoration
""")
