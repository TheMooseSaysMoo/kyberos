"""Tactical-display wallpapers, one per crystal (static), plus a 'base' variant
without the radar sweep for the animated wallpaper plugin to draw over."""
import json
import math
import random
from palette import *
from glyphs import wordmark, text_width, crystal as crystal_svg
import raster

W, H = 3840, 2160
PLANET = (2580, 960, 540)       # cx, cy, r
RADAR = (560, 1660, 300)        # cx, cy, r  (shared with the QML plugin)


def hex_pattern():
    s = 34  # hex radius
    w, h = math.sqrt(3) * s, 1.5 * s
    pts = [(w / 2 + s * math.cos(math.radians(a)), s + s * math.sin(math.radians(a))) for a in range(30, 390, 60)]
    p = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    pts2 = [(x + w / 2 if True else x, y + h) for x, y in pts]
    p2 = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts2)
    return (f'<pattern id="hex" width="{w:.2f}" height="{2 * h:.2f}" patternUnits="userSpaceOnUse">'
            f'<polygon points="{p}" style="fill:none;stroke:#26313f;stroke-width:1.2"/>'
            f'<polygon points="{p2}" style="fill:none;stroke:#26313f;stroke-width:1.2"/></pattern>')


def planet(a):
    cx, cy, r = PLANET
    g = [f'<g transform="rotate(-18 {cx} {cy})" style="fill:none;stroke:{a}">']
    g.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" style="fill:url(#planetfill);stroke-width:3;stroke-opacity:0.75"/>')
    for lat in range(-75, 90, 15):
        y = cy + r * math.sin(math.radians(lat))
        rx = r * math.cos(math.radians(lat))
        g.append(f'<ellipse cx="{cx}" cy="{y:.1f}" rx="{rx:.1f}" ry="{rx * 0.16:.1f}" style="stroke-width:1.4;stroke-opacity:{0.42 if lat == 0 else 0.22}"/>')
    for lon in range(0, 180, 15):
        rx = abs(r * math.cos(math.radians(lon)))
        g.append(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx:.1f}" ry="{r}" style="stroke-width:1.2;stroke-opacity:0.2"/>')
    g.append("</g>")
    # orbit ring and a tracked contact
    g.append(f'<ellipse cx="{cx}" cy="{cy}" rx="{r * 1.75:.0f}" ry="{r * 0.42:.0f}" transform="rotate(-11 {cx} {cy})" '
             f'style="fill:none;stroke:{a};stroke-width:2;stroke-opacity:0.45;stroke-dasharray:14 10"/>')
    tx, ty = cx - r * 1.55, cy + r * 0.48
    g.append(reticle(tx, ty, 26, a))
    # target lock on the planet surface with a leader line to a readout
    lx, ly = cx + r * 0.28, cy - r * 0.34
    g.append(f'<rect x="{lx - 22}" y="{ly - 22}" width="44" height="44" style="fill:none;stroke:{AMBER};stroke-width:2.5"/>')
    g.append(f'<path d="M {lx + 22} {ly - 22} L {lx + 260} {ly - 220} H {lx + 560}" style="fill:none;stroke:{AMBER};stroke-width:2;stroke-opacity:0.8"/>')
    g.append(readout(lx + 280, ly - 300, 280, 6, AMBER, seed=7))
    return "".join(g)


def reticle(x, y, s, col):
    return (f'<g style="fill:none;stroke:{col};stroke-width:2.5">'
            f'<path d="M {x - s} {y - s / 2} V {y - s} H {x - s / 2} M {x + s / 2} {y - s} H {x + s} V {y - s / 2} '
            f'M {x + s} {y + s / 2} V {y + s} H {x + s / 2} M {x - s / 2} {y + s} H {x - s} V {y + s / 2}"/>'
            f'<circle cx="{x}" cy="{y}" r="4" style="fill:{col}"/></g>')


def readout(x, y, w, rows, col, seed=1, row_h=20):
    rnd = random.Random(seed)
    out = [f'<g style="fill:{col}">']
    for i in range(rows):
        ry = y + i * (row_h + 10)
        out.append(f'<rect x="{x}" y="{ry}" width="10" height="{row_h}" style="fill-opacity:0.9"/>')
        cx = x + 22
        while cx < x + w:
            seg = rnd.choice([18, 30, 46, 64, 12])
            if cx + seg > x + w:
                break
            out.append(f'<rect x="{cx}" y="{ry + row_h * 0.3:.0f}" width="{seg}" height="{row_h * 0.4:.0f}" style="fill-opacity:{rnd.choice([0.25, 0.4, 0.6])}"/>')
            cx += seg + 8
    out.append("</g>")
    return "".join(out)


def radar(a, sweep=True):
    cx, cy, r = RADAR
    g = [f'<g style="fill:none;stroke:{a}">']
    g.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" style="fill:{VOID};fill-opacity:0.55;stroke-width:3;stroke-opacity:0.7"/>')
    for f in (0.25, 0.5, 0.75):
        g.append(f'<circle cx="{cx}" cy="{cy}" r="{r * f}" style="stroke-width:1.5;stroke-opacity:0.3"/>')
    g.append(f'<path d="M {cx - r} {cy} H {cx + r} M {cx} {cy - r} V {cy + r}" style="stroke-width:1.2;stroke-opacity:0.3"/>')
    for i in range(72):
        ang = math.radians(i * 5)
        l = 18 if i % 6 == 0 else 8
        x1, y1 = cx + r * math.cos(ang), cy + r * math.sin(ang)
        x2, y2 = cx + (r + l) * math.cos(ang), cy + (r + l) * math.sin(ang)
        g.append(f'<path d="M {x1:.1f} {y1:.1f} L {x2:.1f} {y2:.1f}" style="stroke-width:2;stroke-opacity:0.6"/>')
    if sweep:
        a0, a1 = math.radians(-70), math.radians(-20)
        g.append(f'<path d="M {cx} {cy} L {cx + r * math.cos(a0):.1f} {cy + r * math.sin(a0):.1f} '
                 f'A {r} {r} 0 0 1 {cx + r * math.cos(a1):.1f} {cy + r * math.sin(a1):.1f} Z" '
                 f'style="fill:url(#sweep);stroke:none"/>')
        g.append(f'<path d="M {cx} {cy} L {cx + r * math.cos(a1):.1f} {cy + r * math.sin(a1):.1f}" style="stroke-width:3;stroke-opacity:0.9"/>')
    rnd = random.Random(3)
    for _ in range(5):
        ang, d = rnd.uniform(0, 6.28), rnd.uniform(0.2, 0.9) * r
        g.append(f'<rect x="{cx + d * math.cos(ang) - 5:.0f}" y="{cy + d * math.sin(ang) - 5:.0f}" width="10" height="10" style="fill:{a};stroke:none;fill-opacity:0.85"/>')
    g.append("</g>")
    return "".join(g)


def frame_marks():
    out = [f'<g style="fill:none;stroke:{EDGE};stroke-width:3;stroke-opacity:0.8">']
    m, l = 60, 120
    for x, y, dx, dy in [(m, m, 1, 1), (W - m, m, -1, 1), (m, H - m, 1, -1), (W - m, H - m, -1, -1)]:
        out.append(f'<path d="M {x} {y + dy * l} V {y} H {x + dx * l}"/>')
    out.append("</g>")
    # left ruler
    out.append(f'<g style="stroke:{EDGE};stroke-width:2;stroke-opacity:0.55">')
    for i, y in enumerate(range(260, H - 260, 24)):
        l = 34 if i % 5 == 0 else 14
        out.append(f'<path d="M 64 {y} H {64 + l}"/>')
    out.append("</g>")
    return "".join(out)


def svg(crystal, sweep=True):
    a = CRYSTALS[crystal]
    leds = []
    rnd = random.Random(11)
    for i in range(14):
        col = rnd.choice([a, a, DATA, AMBER, ALERT, EDGE, EDGE])
        leds.append(f'<rect x="{200 + i * 26}" y="226" width="14" height="8" style="fill:{col};fill-opacity:0.9"/>')
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<defs>
  <radialGradient id="bg" cx="0.62" cy="0.42" r="0.85">
    <stop offset="0" stop-color="#121b25"/><stop offset="0.55" stop-color="#0a0e13"/><stop offset="1" stop-color="{VOID}"/>
  </radialGradient>
  <radialGradient id="planetfill" cx="0.4" cy="0.35" r="0.75">
    <stop offset="0" stop-color="{a}" stop-opacity="0.16"/><stop offset="1" stop-color="{a}" stop-opacity="0.02"/>
  </radialGradient>
  <radialGradient id="hexfade" cx="0.62" cy="0.45" r="0.7">
    <stop offset="0" stop-color="#fff" stop-opacity="0.55"/><stop offset="1" stop-color="#fff" stop-opacity="0.05"/>
  </radialGradient>
  <mask id="hexmask"><rect width="{W}" height="{H}" fill="url(#hexfade)"/></mask>
  <linearGradient id="sweep" x1="0" y1="1" x2="1" y2="0">
    <stop offset="0" stop-color="{a}" stop-opacity="0"/><stop offset="1" stop-color="{a}" stop-opacity="0.45"/>
  </linearGradient>
  {hex_pattern()}
  <pattern id="scan" width="8" height="6" patternUnits="userSpaceOnUse"><rect width="8" height="2" fill="#000" fill-opacity="0.22"/></pattern>
  <radialGradient id="vignette" cx="0.5" cy="0.5" r="0.75">
    <stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.65"/>
  </radialGradient>
</defs>
<rect width="{W}" height="{H}" fill="url(#bg)"/>
<rect width="{W}" height="{H}" fill="url(#hex)" mask="url(#hexmask)"/>
{planet(a)}
{radar(a, sweep)}
{frame_marks()}
{readout(200, 260, 420, 5, DATA, seed=2)}
{''.join(leds)}
{readout(W - 760, H - 470, 520, 3, a, seed=5)}
<g opacity="0.75">{crystal_svg(W - 560 - text_width('KYBER OS', 7.5) / 2 - 48, H - 260, 74, a)}{wordmark(W - 560, H - 260, 7.5, TEXT, a)}</g>
<rect width="{W}" height="{H}" fill="url(#scan)"/>
<rect width="{W}" height="{H}" fill="url(#vignette)"/>
</svg>
"""


def generate(out):
    for crystal in CRYSTALS:
        name = f"KyberOS-{crystal.capitalize()}"
        d = out / "wallpapers" / name
        img = d / "contents" / "images"
        img.mkdir(parents=True, exist_ok=True)
        src = d / "source.svg"
        src.write_text(svg(crystal, sweep=True))
        if raster.png(src, img / f"{W}x{H}.png"):
            raster.png(src, d / "contents" / "screenshot.png", 480, 270)
        src.unlink(missing_ok=True) if (img / f"{W}x{H}.png").exists() else None
        (d / "metadata.json").write_text(json.dumps({"KPlugin": {
            "Id": name, "Name": f"KyberOS {crystal.capitalize()} Crystal",
            "Authors": [{"Name": "KyberOS"}], "License": "CC-BY-SA-4.0"}}, indent=2))
        # wordmark for the animated plugin (scenes themselves are drawn in QML)
        wm = out / "plasma" / "wallpapers" / "org.kyberos.tactical" / "contents" / "images"
        wm.mkdir(parents=True, exist_ok=True)
        tw = text_width("KYBER OS", 7.5)
        (wm / f"wordmark-{crystal}.svg").write_text(
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{tw + 160:.0f}" height="160" viewBox="0 0 {tw + 160:.0f} 160">'
            f'{crystal_svg(40, 80, 74, CRYSTALS[crystal])}{wordmark(120 + tw / 2, 80, 7.5, TEXT, CRYSTALS[crystal])}</svg>\n')
