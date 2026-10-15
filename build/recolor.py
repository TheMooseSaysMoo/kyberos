"""Recolour a third-party stylesheet onto the KyberOS palette.

Used for the vendored Mint-Y base (GTK 3/4, Cinnamon). Instead of a hand-made
table for 70-odd colours, every colour is classified by hue/saturation:
  greys          -> the KyberOS blue-steel ramp, by lightness
  blues (accent) -> the kyber crystal, keeping the shade offset from Mint's accent
  reds / oranges / greens -> ALERT / AMBER / OK families, same idea
Handles #rgb, #rrggbb, rgb() and rgba().
"""
import colorsys
import re

from palette import VOID, DEEP, PANEL, STEEL, RAISED, BEVEL, EDGE, DIM, TEXT, AMBER, ALERT, OK, rgb

# Mint-Y lightness -> KyberOS steel (piecewise, interpolated in RGB)
RAMP = [
    (0.00, "#000000"), (0.06, VOID), (0.10, DEEP), (0.13, PANEL), (0.19, STEEL),
    (0.23, RAISED), (0.27, BEVEL), (0.40, EDGE), (0.58, DIM), (0.86, TEXT), (1.00, "#f4f8fc"),
]
# reference colour of each family in Mint-Y (accent / destructive / warning / success)
MINT_ACCENT, MINT_RED, MINT_ORANGE, MINT_GREEN = "#1f9ede", "#f04a50", "#f27835", "#6db442"


def _hls(c):
    r, g, b = (x / 255 for x in rgb(c))
    return colorsys.rgb_to_hls(r, g, b)


def _hex(r, g, b):
    return "#" + "".join(f"{max(0, min(255, round(x * 255))):02x}" for x in (r, g, b))


def _lerp(a, b, t):
    ra, rb = rgb(a), rgb(b)
    return _hex(*((x + (y - x) * t) / 255 for x, y in zip(ra, rb)))


def steel(l):
    for (l0, c0), (l1, c1) in zip(RAMP, RAMP[1:]):
        if l <= l1:
            return _lerp(c0, c1, (l - l0) / (l1 - l0) if l1 > l0 else 0)
    return RAMP[-1][1]


def shade(src, ref, target):
    """Move target by the lightness offset of src from ref (keeps hover/pressed shades)."""
    hs, ls, ss = _hls(src)
    hr, lr, sr = _hls(ref)
    ht, lt, st = _hls(target)
    l = max(0.04, min(0.97, lt + (ls - lr)))
    s = st * (ss / sr if sr else 1)
    return _hex(*colorsys.hls_to_rgb(ht, l, max(0, min(1, s))))


def map_colour(c, accent):
    h, l, s = _hls(c)
    if s < 0.18 or (l > 0.9 and s < 0.5) or l < 0.03:
        return steel(l)
    deg = h * 360
    if 180 <= deg <= 235:
        return shade(c, MINT_ACCENT, accent)
    if deg < 15 or deg >= 330:
        return shade(c, MINT_RED, ALERT)
    if 15 <= deg < 50:
        return shade(c, MINT_ORANGE, AMBER)
    if 70 <= deg < 170:
        return shade(c, MINT_GREEN, OK)
    return steel(l)


_HEX = re.compile(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b")
_RGBA = re.compile(r"rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(,\s*[0-9.]+\s*)?\)")


_VALUE = re.compile(r":[^;{}]*[;}]")                    # a property value, up to ; or }
_DEFINE = re.compile(r"@define-color\s+\S+\s+[^;]+;")


def recolor(text, accent):
    """Recolour values only: selectors like '#add-workspace' or '#panel' look like colours."""
    return _DEFINE.sub(lambda m: _recolor_values(m.group(), accent),
                       _VALUE.sub(lambda m: _recolor_values(m.group(), accent), text))


def _recolor_values(text, accent):
    def hx(m):
        v = m.group(1)
        if len(v) == 3:
            v = "".join(ch * 2 for ch in v)
        return map_colour("#" + v.lower(), accent)

    def rg(m):
        c = map_colour("#%02x%02x%02x" % tuple(int(m.group(i)) for i in (1, 2, 3)), accent)
        r, g, b = rgb(c)
        return f"rgba({r}, {g}, {b}{m.group(4) or ', 1'})"

    return _RGBA.sub(rg, _HEX.sub(hx, text))
