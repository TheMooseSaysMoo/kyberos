"""9-slice SVG frame builder for Plasma styles and Aurorae.

A frame is drawn as nine separate elements (<prefix>-topleft ... <prefix>-center).
Plasma's FrameSvg measures each element's bounding box, so every piece is drawn
strictly inside its own tile with filled polygons (no strokes, which would make
bounds depend on the renderer) plus a near-invisible sizing rect.
"""
from dataclasses import dataclass, field
import math

COLOR_STYLE = """<style id="current-color-scheme" type="text/css">
.ColorScheme-Text {{ color:{text}; }}
.ColorScheme-Background {{ color:{bg}; }}
.ColorScheme-ViewBackground {{ color:{view}; }}
.ColorScheme-ButtonBackground {{ color:{button}; }}
.ColorScheme-Highlight {{ color:{accent}; }}
.ColorScheme-HighlightedText {{ color:{text}; }}
.ColorScheme-NeutralText {{ color:{amber}; }}
.ColorScheme-NegativeText {{ color:{alert}; }}
.ColorScheme-PositiveText {{ color:{ok}; }}
</style>"""


def paint(p):
    """A paint is '#rrggbb', a 'ColorScheme-*' class name, or a (paint, opacity) tuple."""
    if isinstance(p, tuple):
        p, op = p
    else:
        op = 1
    if p.startswith("ColorScheme-"):
        return f'class="{p}" style="fill:currentColor;fill-opacity:{op}"'
    return f'style="fill:{p};fill-opacity:{op}"'


def poly(points, p):
    pts = " ".join(f"{x:.3f},{y:.3f}" for x, y in points)
    return f'<polygon points="{pts}" {paint(p)}/>'


def sizer(x, y, w, h):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" style="fill:#000000;fill-opacity:0.004"/>'


@dataclass
class Frame:
    prefix: str = ""
    corner: int = 10              # corner tile size (= content margin)
    chamfer: int = 0              # chamfer size, 0 = square corner
    chamfered: tuple = ("topleft", "bottomright")
    fill: object = None           # paint for the body
    border: object = None         # paint for the outline
    border_w: float = 1
    diag: object = None           # paint for chamfer diagonals (accent)
    bars: dict = field(default_factory=dict)  # side -> (paint, thickness)
    edge: int = 4                 # length of the stretched edge tiles
    margins: dict = None          # optional hint margins
    bare_center: bool = False     # Kvantum names the fill "<prefix>", not "<prefix>-center"

    def eid(self, piece):
        if piece == "center" and self.bare_center:
            return self.prefix
        return f"{self.prefix}-{piece}" if self.prefix else piece

    # --- corner pieces, drawn as top-left then mirrored ---
    def _corner_shapes(self, chamfered):
        c, k, w = self.corner, self.chamfer if chamfered else 0, self.border_w
        shapes = []
        if k:
            outer = [(0, k), (k, 0), (c, 0), (c, c), (0, c)]
        else:
            outer = [(0, 0), (c, 0), (c, c), (0, c)]
        if self.fill:
            shapes.append((outer, self.fill))
        if self.border:
            if k:
                d = w * (math.sqrt(2) - 1)
                shapes.append(([(0, c), (0, k), (k, 0), (c, 0), (c, w), (k + d, w), (w, k + d), (w, c)], self.border))
            else:
                shapes.append(([(0, c), (0, 0), (c, 0), (c, w), (w, w), (w, c)], self.border))
        if k and self.diag:
            dw = max(w, 1.5)
            d = dw * (math.sqrt(2) - 1)
            shapes.append(([(0, k), (k, 0), (k + d, dw), (dw, k + d)], self.diag))
        return shapes

    def _bar_shapes_corner(self, piece):
        """Accent bars continue through the corner tiles of their side."""
        c = self.corner
        out = []
        for side, (p, t) in self.bars.items():
            if side == "bottom" and piece.startswith("bottom"):
                out.append(([(0, c - t), (c, c - t), (c, c), (0, c)], p))
            if side == "top" and piece.startswith("top"):
                out.append(([(0, 0), (c, 0), (c, t), (0, t)], p))
        return out

    def svg(self, ox, oy):
        """Return (svg_text, width, height) of all pieces laid out from (ox, oy)."""
        c, e, w = self.corner, self.edge, self.border_w
        cols = [(0, c), (c + 2, e), (c + e + 4, c)]   # x offset, width
        rows = [(0, c), (c + 2, e), (c + e + 4, c)]
        names = [["topleft", "top", "topright"], ["left", "center", "right"], ["bottomleft", "bottom", "bottomright"]]
        out = []
        for ri, (ry, rh) in enumerate(rows):
            for ci, (cx, cw) in enumerate(cols):
                piece = names[ri][ci]
                x0, y0 = ox + cx, oy + ry
                shapes = []
                if piece in ("topleft", "topright", "bottomleft", "bottomright"):
                    fx = piece.endswith("right")
                    fy = piece.startswith("bottom")
                    local = self._corner_shapes(piece in self.chamfered)
                    mapped = []
                    for pts, p in local:
                        mapped.append(([((c - x) if fx else x, (c - y) if fy else y) for x, y in pts], p))
                    # bars are defined in already-oriented coordinates
                    mapped += [([(x, y) for x, y in pts], p) for pts, p in self._bar_shapes_corner(piece)]
                    shapes = mapped
                elif piece == "center":
                    if self.fill:
                        shapes.append(([(0, 0), (e, 0), (e, e), (0, e)], self.fill))
                else:
                    horiz = piece in ("top", "bottom")
                    W, H = (e, c) if horiz else (c, e)
                    if self.fill:
                        shapes.append(([(0, 0), (W, 0), (W, H), (0, H)], self.fill))
                    if self.border:
                        if piece == "top":
                            shapes.append(([(0, 0), (W, 0), (W, w), (0, w)], self.border))
                        elif piece == "bottom":
                            shapes.append(([(0, H - w), (W, H - w), (W, H), (0, H)], self.border))
                        elif piece == "left":
                            shapes.append(([(0, 0), (w, 0), (w, H), (0, H)], self.border))
                        else:
                            shapes.append(([(W - w, 0), (W, 0), (W, H), (W - w, H)], self.border))
                    for side, (p, t) in self.bars.items():
                        if side == piece == "bottom":
                            shapes.append(([(0, H - t), (W, H - t), (W, H), (0, H)], p))
                        if side == piece == "top":
                            shapes.append(([(0, 0), (W, 0), (W, t), (0, t)], p))
                tw, th = cw, rh
                body = [sizer(x0, y0, tw, th)]
                body += [poly([(x0 + x, y0 + y) for x, y in pts], p) for pts, p in shapes]
                out.append(f'<g id="{self.eid(piece)}">{"".join(body)}</g>')
        if self.margins:
            hy = oy
            for side, val in self.margins.items():
                hid = f"{self.prefix}-hint-{side}-margin" if self.prefix else f"hint-{side}-margin"
                ww, hh = (val, 1) if side in ("left", "right") else (1, val)
                out.append(f'<rect id="{hid}" x="{ox + 2 * c + e + 10}" y="{hy}" width="{ww}" height="{hh}" style="fill:#000000;fill-opacity:0.004"/>')
                hy += val + 2
        size = 2 * c + e + 4
        return "\n".join(out), size + 30, size


def document(frames, colors, extra="", extra_size=(0, 0), stretch=True):
    """Stack several Frames vertically into one SVG document."""
    parts, y, wmax = [], 0, 0
    for f in frames:
        s, w, h = f.svg(0, y)
        parts.append(s)
        y += h + 6
        wmax = max(wmax, w)
    if stretch:
        parts.append(f'<rect id="hint-stretch-borders" x="{wmax}" y="0" width="2" height="2" style="fill:#000000;fill-opacity:0.004"/>')
    width = max(wmax + 4, extra_size[0])
    height = y + extra_size[1]
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
{COLOR_STYLE.format(**colors)}
{chr(10).join(parts)}
{extra}
</svg>
"""
