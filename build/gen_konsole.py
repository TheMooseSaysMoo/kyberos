"""Konsole colour scheme + profile: phosphor-on-void terminal."""
from palette import *

ANSI = [
    # normal, intense
    (VOID, "#3a4553"),          # black
    (ALERT, "#ff6a5c"),         # red
    (OK, "#7dffb4"),            # green
    (AMBER, "#ffd07a"),         # yellow
    ("#3d8bff", "#7fb4ff"),     # blue
    ("#b264ff", "#d2a2ff"),     # magenta
    ("#33d6e0", "#8cf1f6"),     # cyan
    (TEXT, "#ffffff"),          # white
]


def block(name, colour):
    return f"[{name}]\nColor={kde(colour)}\n\n"


def scheme(crystal):
    s = block("Background", VOID) + block("BackgroundIntense", PANEL) + block("BackgroundFaint", VOID)
    s += block("Foreground", DATA) + block("ForegroundIntense", "#ffffff") + block("ForegroundFaint", DIM)
    for i, (n, b) in enumerate(ANSI):
        if i == 4:
            n, b = CRYSTALS[crystal], mix(CRYSTALS[crystal], "#ffffff", 0.35)
        s += block(f"Color{i}", n) + block(f"Color{i}Intense", b) + block(f"Color{i}Faint", mix(n, VOID, 0.4))
    s += f"[General]\nAnchor=0.5,0.5\nBlur=true\nColorRandomization=false\nDescription=KyberOS {crystal.capitalize()}\nFillStyle=Tile\nOpacity=0.93\nWallpaper=\nWallpaperFlipType=NoFlip\nWallpaperOpacity=1\n"
    return s


def generate(out):
    d = out / "konsole"
    d.mkdir(parents=True, exist_ok=True)
    for crystal in CRYSTALS:
        (d / f"KyberOS{crystal.capitalize()}.colorscheme").write_text(scheme(crystal))
    (d / "KyberOS.profile").write_text(f"""[Appearance]
ColorScheme=KyberOS{DEFAULT_CRYSTAL.capitalize()}
Font={FONTS['mono']},12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
CursorShape=0

[Cursor Options]
CursorShape=0

[General]
Command=/bin/bash
Name=KyberOS
Parent=FALLBACK/
TerminalMargin=8

[Scrolling]
ScrollBarPosition=2
""")
