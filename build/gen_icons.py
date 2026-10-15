"""'KyberOS' icon theme: overrides places + a few apps, inherits Breeze Dark.

Icons carry KDE's current-color-scheme stylesheet, so ColorScheme-Highlight
parts take the active crystal colour.
"""
from palette import *

STYLE = f"""<style id="current-color-scheme" type="text/css">
.ColorScheme-Highlight {{ color:{CRYSTALS[DEFAULT_CRYSTAL]}; }}
.ColorScheme-Text {{ color:{TEXT}; }}
</style>"""
HL = 'class="ColorScheme-Highlight"'


def doc(body, size=64):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 64 64">{STYLE}{body}</svg>\n'


def cartridge(glyph=""):
    """Folder = chamfered data cartridge with a lit accent strip."""
    body = (
        # tab
        f'<path d="M 6 14 L 10 10 H 26 L 30 14 Z" style="fill:{BEVEL}"/>'
        # body
        f'<path d="M 4 18 L 10 13 H 60 V 50 L 54 56 H 4 Z" style="fill:{STEEL};stroke:{EDGE};stroke-width:1.5"/>'
        f'<path d="M 4 18 L 10 13 H 60 V 22 H 4 Z" style="fill:{RAISED}"/>'
        # accent strip + chamfer diagonal
        f'<rect x="10" y="17" width="44" height="2.5" {HL} style="fill:currentColor"/>'
        f'<path d="M 54 56 L 60 50" {HL} style="fill:none;stroke:currentColor;stroke-width:2.5"/>'
        # grip ridges
        f'<path d="M 9 47 H 21 M 9 50.5 H 21" style="stroke:{EDGE};stroke-width:1.5"/>'
    )
    return doc(body + glyph)


def g_path(d, w=3):
    return f'<path d="{d}" {HL} style="fill:none;stroke:currentColor;stroke-width:{w};stroke-linecap:square;stroke-linejoin:miter"/>'


PLACE_GLYPHS = {
    "folder": "",
    "folder-documents": g_path("M 26 29 H 46 M 26 35 H 46 M 26 41 H 38"),
    "folder-download": g_path("M 36 27 V 43 M 29 37 L 36 44 L 43 37"),
    "folder-music": g_path("M 30 43 V 29 L 44 27 V 41") + f'<circle cx="28" cy="43" r="3" {HL} style="fill:currentColor"/><circle cx="42" cy="41" r="3" {HL} style="fill:currentColor"/>',
    "folder-pictures": g_path("M 25 44 L 32 35 L 37 40 L 41 36 L 47 44 Z", 2.5),
    "folder-videos": g_path("M 27 30 H 45 V 43 H 27 Z M 33 33 L 39 36.5 L 33 40 Z", 2.5),
    "folder-pictures-screenshots": g_path("M 26 30 V 27 H 29 M 43 27 H 46 V 30 M 46 41 V 44 H 43 M 29 44 H 26 V 41", 2.5),
    "folder-publicshare": g_path("M 28 36 L 44 30 M 28 36 L 44 42", 2.5),
    "folder-templates": g_path("M 28 28 H 44 V 44 H 28 Z M 28 34 H 44", 2.5),
    "folder-cloud": g_path("M 28 42 H 44 A 5 5 0 0 0 42 33 A 7 7 0 0 0 30 34 A 4 4 0 0 0 28 42 Z", 2.5),
    "folder-git": g_path("M 30 28 V 44 M 30 34 L 42 30 M 42 30 V 32", 2.5),
    "folder-development": g_path("M 30 30 L 25 36 L 30 42 M 42 30 L 47 36 L 42 42", 2.5),
    "user-desktop": g_path("M 26 29 H 46 V 41 H 26 Z M 32 45 H 40", 2.5),
    "user-home": g_path("M 25 37 L 36 28 L 47 37 M 29 35 V 45 H 43 V 35", 2.5),
}


def trash(full=False):
    body = (f'<path d="M 14 16 H 50 L 46 58 H 18 Z" style="fill:{STEEL};stroke:{EDGE};stroke-width:1.5"/>'
            f'<path d="M 10 12 H 54 V 17 H 10 Z" style="fill:{RAISED};stroke:{EDGE};stroke-width:1.5"/>'
            f'<path d="M 25 8 H 39 V 12 H 25 Z" style="fill:{BEVEL}"/>'
            f'<path d="M 24 24 V 50 M 32 24 V 50 M 40 24 V 50" style="stroke:{BEVEL};stroke-width:2.5"/>')
    if full:
        body += f'<rect x="18" y="20" width="28" height="4" {HL} style="fill:currentColor"/>'
        body += f'<circle cx="46" cy="14" r="5" style="fill:{AMBER}"/>'
    return doc(body)


def terminal():
    return doc(f'<path d="M 4 10 L 10 4 H 60 V 54 L 54 60 H 4 Z" style="fill:{VOID};stroke:{EDGE};stroke-width:2"/>'
               f'<rect x="4" y="4" width="56" height="8" style="fill:{STEEL}"/>'
               f'<path d="M 4 10 L 10 4" {HL} style="stroke:currentColor;stroke-width:2.5"/>'
               + g_path("M 14 24 L 22 31 L 14 38", 3.5)
               + f'<rect x="26" y="36" width="14" height="3.5" style="fill:{DATA}"/>'
               + f'<path d="M 14 48 H 50" style="stroke:{BEVEL};stroke-width:2"/>')


def settings():
    import math
    cx, cy = 32, 32
    teeth = []
    for i in range(6):
        a = math.radians(i * 60)
        teeth.append(f'<rect x="{cx - 5}" y="4" width="10" height="12" transform="rotate({i * 60} {cx} {cy})" style="fill:{STEEL};stroke:{EDGE};stroke-width:1.5"/>')
    return doc("".join(teeth)
               + f'<polygon points="32,10 51,21 51,43 32,54 13,43 13,21" style="fill:{STEEL};stroke:{EDGE};stroke-width:1.5"/>'
               + f'<polygon points="32,22 41,27 41,37 32,42 23,37 23,27" {HL} style="fill:none;stroke:currentColor;stroke-width:3"/>'
               + f'<circle cx="32" cy="32" r="3.5" {HL} style="fill:currentColor"/>')


def kyber_start():
    """Start menu: kyber crystal inside a segmented targeting ring."""
    import math
    segs = []
    for i in range(6):
        a0, a1 = math.radians(i * 60 + 8), math.radians(i * 60 + 52)
        r = 28
        segs.append(f'<path d="M {32 + r * math.cos(a0):.2f} {32 + r * math.sin(a0):.2f} A {r} {r} 0 0 1 {32 + r * math.cos(a1):.2f} {32 + r * math.sin(a1):.2f}" '
                    f'style="fill:none;stroke:{EDGE};stroke-width:4"/>')
    crystal = (f'<polygon points="32,8 41,19 41,45 32,56 23,45 23,19" {HL} style="fill:currentColor;fill-opacity:0.9"/>'
               f'<polygon points="32,15 35,22 35,42 32,49 29,42 29,22" style="fill:#f4fbff;fill-opacity:0.92"/>')
    return doc("".join(segs) + crystal)


def store():
    return doc(f'<path d="M 8 20 L 14 14 H 56 V 52 L 50 58 H 8 Z" style="fill:{STEEL};stroke:{EDGE};stroke-width:1.5"/>'
               f'<path d="M 22 14 V 10 L 26 6 H 38 L 42 10 V 14" style="fill:none;stroke:{EDGE};stroke-width:3"/>'
               + g_path("M 32 26 V 44 M 25 37 L 32 44 L 39 37", 3.5))


def generate(out):
    base = out / "icons" / "KyberOS"
    places = base / "scalable" / "places"
    apps = base / "scalable" / "apps"
    places.mkdir(parents=True, exist_ok=True)
    apps.mkdir(parents=True, exist_ok=True)
    for name, glyph in PLACE_GLYPHS.items():
        (places / f"{name}.svg").write_text(cartridge(glyph))
    for alias, target in [("folder-open", "folder"), ("inode-directory", "folder"), ("folder-documents-open", "folder-documents"),
                          ("folder-image", "folder-pictures"), ("folder-video", "folder-videos"), ("folder-sound", "folder-music"),
                          ("folder-downloads", "folder-download"), ("folder-desktop", "user-desktop"), ("folder-home", "user-home"),
                          ("folder-image-people", "folder-pictures"), ("folder-script", "folder-development")]:
        (places / f"{alias}.svg").write_text((places / f"{target}.svg").read_text())
    (places / "user-trash.svg").write_text(trash(False))
    (places / "user-trash-full.svg").write_text(trash(True))
    (places / "start-here-kde-plasma.svg").write_text(kyber_start())
    for name, fn in [("kyberos", kyber_start), ("start-here", kyber_start), ("start-here-kde", kyber_start),
                     ("start-here-kyberos", kyber_start),
                     ("utilities-terminal", terminal), ("org.kde.konsole", terminal),
                     ("preferences-system", settings), ("systemsettings", settings),
                     ("plasmadiscover", store), ("org.kde.discover", store)]:
        (apps / f"{name}.svg").write_text(fn())
    (base / "index.theme").write_text("""[Icon Theme]
Name=KyberOS
Comment=Imperial console icons (inherits Breeze Dark)
Inherits=breeze-dark,breeze,hicolor
DisplayDepth=32
Directories=scalable/places,scalable/apps
FollowsColorScheme=true

[scalable/places]
Size=64
MinSize=8
MaxSize=512
Context=Places
Type=Scalable

[scalable/apps]
Size=64
MinSize=8
MaxSize=512
Context=Applications
Type=Scalable
""")
