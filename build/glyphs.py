"""Hand-drawn angular stencil letters for the KyberOS wordmark (no font needed).

Glyphs sit on an 8x12 grid; each is a list of polylines drawn as strokes.
"""

GLYPHS = {
    "K": [[(0, 0), (0, 12)], [(8, 0), (2.2, 6), (8, 12)]],
    "Y": [[(0, 0), (4, 5.5), (8, 0)], [(4, 5.5), (4, 12)]],
    "B": [[(0, 0), (0, 12)], [(0, 0), (6, 0), (8, 2), (8, 4), (6, 6), (0, 6)],
          [(0, 6), (6, 6), (8, 8), (8, 10), (6, 12), (0, 12)]],
    "E": [[(8, 0), (0, 0), (0, 12), (8, 12)], [(0, 6), (6, 6)]],
    "R": [[(0, 12), (0, 0), (6, 0), (8, 2), (8, 4), (6, 6), (0, 6)], [(4, 6), (8, 12)]],
    "O": [[(2.5, 0), (8, 0), (8, 9.5), (5.5, 12), (0, 12), (0, 2.5), (2.5, 0)]],
    "S": [[(8, 0), (2, 0), (0, 2), (0, 5), (1, 6), (7, 6), (8, 7), (8, 10), (6, 12), (0, 12)]],
    "A": [[(0, 12), (0, 3), (3, 0), (8, 0), (8, 12)], [(0, 7), (8, 7)]],
    "C": [[(8, 0), (2.5, 0), (0, 2.5), (0, 12), (8, 12)]],
    "D": [[(0, 0), (0, 12), (5.5, 12), (8, 9.5), (8, 0), (0, 0)]],
    "I": [[(4, 0), (4, 12)], [(1, 0), (7, 0)], [(1, 12), (7, 12)]],
    "L": [[(0, 0), (0, 12), (8, 12)]],
    "N": [[(0, 12), (0, 0), (8, 12), (8, 0)]],
    "T": [[(0, 0), (8, 0)], [(4, 0), (4, 12)]],
    "U": [[(0, 0), (0, 12), (8, 12), (8, 0)]],
    "G": [[(8, 0), (2.5, 0), (0, 2.5), (0, 12), (8, 12), (8, 6), (4, 6)]],
    "H": [[(0, 0), (0, 12)], [(8, 0), (8, 12)], [(0, 6), (8, 6)]],
    "M": [[(0, 12), (0, 0), (4, 5), (8, 0), (8, 12)]],
    "P": [[(0, 12), (0, 0), (6, 0), (8, 2), (8, 4), (6, 6), (0, 6)]],
    "W": [[(0, 0), (0, 12), (4, 7), (8, 12), (8, 0)]],
    "V": [[(0, 0), (4, 12), (8, 0)]],
    "-": [[(1, 6), (7, 6)]],
    " ": [],
}
ADVANCE = 11.5


def text_width(text, scale):
    return (len(text) * ADVANCE - (ADVANCE - 8)) * scale


def text_svg(text, x, y, scale, colour, stroke=1.5, opacity=1.0):
    """SVG <g> drawing `text` with its top-left at (x, y)."""
    paths = []
    for i, ch in enumerate(text.upper()):
        ox = x + i * ADVANCE * scale
        for line in GLYPHS.get(ch, []):
            d = "M " + " L ".join(f"{ox + px * scale:.2f} {y + py * scale:.2f}" for px, py in line)
            paths.append(f'<path d="{d}"/>')
    return (f'<g style="fill:none;stroke:{colour};stroke-opacity:{opacity};stroke-width:{stroke * scale:.2f};'
            f'stroke-linecap:square;stroke-linejoin:miter">{"".join(paths)}</g>')


def wordmark(cx, cy, scale, bright, accent, dim_gap=True):
    """'KYBER OS' centred on (cx, cy): KYBER in bright, OS in the accent."""
    full = "KYBER OS"
    w = text_width(full, scale)
    x0 = cx - w / 2
    y0 = cy - 6 * scale
    kyber = text_svg("KYBER", x0, y0, scale, bright)
    os_ = text_svg("OS", x0 + 6 * ADVANCE * scale, y0, scale, accent)
    return kyber + os_


def crystal(cx, cy, size, accent, core="#f4fbff"):
    """Faceted kyber crystal (elongated hexagonal prism) centred at (cx, cy)."""
    h, w = size, size * 0.42
    top, bot = cy - h / 2, cy + h / 2
    pts_outer = [(cx, top), (cx + w / 2, top + h * 0.22), (cx + w / 2, bot - h * 0.22),
                 (cx, bot), (cx - w / 2, bot - h * 0.22), (cx - w / 2, top + h * 0.22)]
    pts_core = [(cx, top + h * 0.12), (cx + w * 0.16, top + h * 0.28), (cx + w * 0.16, bot - h * 0.28),
                (cx, bot - h * 0.12), (cx - w * 0.16, bot - h * 0.28), (cx - w * 0.16, top + h * 0.28)]
    o = " ".join(f"{x:.2f},{y:.2f}" for x, y in pts_outer)
    c = " ".join(f"{x:.2f},{y:.2f}" for x, y in pts_core)
    facet = f"M {cx:.2f} {top:.2f} L {cx:.2f} {bot:.2f}"
    return (f'<polygon points="{o}" style="fill:{accent};fill-opacity:0.85;stroke:{accent};stroke-width:{size * 0.03:.2f}"/>'
            f'<polygon points="{c}" style="fill:{core};fill-opacity:0.9"/>'
            f'<path d="{facet}" style="stroke:{core};stroke-opacity:0.5;stroke-width:{size * 0.015:.2f}"/>')
