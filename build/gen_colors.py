"""KDE colour schemes: one per kyber crystal (KyberOS<Crystal>.colors)."""
from palette import *


def section(name, bg, alt, fg, accent, inactive=DIM):
    return f"""[{name}]
BackgroundAlternate={kde(alt)}
BackgroundNormal={kde(bg)}
DecorationFocus={kde(accent)}
DecorationHover={kde(mix(accent, TEXT, 0.25))}
ForegroundActive={kde(accent)}
ForegroundInactive={kde(inactive)}
ForegroundLink={kde(mix(accent, TEXT, 0.15))}
ForegroundNegative={kde(ALERT)}
ForegroundNeutral={kde(AMBER)}
ForegroundNormal={kde(fg)}
ForegroundPositive={kde(OK)}
ForegroundVisited={kde(mix(accent, '#b264ff' if accent != CRYSTALS['purple'] else '#ff7bd5', 0.5))}
"""


def scheme(crystal):
    a = CRYSTALS[crystal]
    title = crystal.capitalize()
    sel_bg = mix(PANEL, a, 0.55)
    parts = [
        f"""[ColorEffects:Disabled]
Color={kde(PANEL)}
ColorAmount=0.55
ColorEffect=3
ContrastAmount=0.65
ContrastEffect=0
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color={kde(VOID)}
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0
""",
        section("Colors:Button", STEEL, RAISED, TEXT, a),
        section("Colors:Complementary", VOID, PANEL, TEXT, a),
        section("Colors:Header", PANEL, STEEL, TEXT, a),
        section("Colors:Header][Inactive", PANEL, STEEL, DIM, a),
        section("Colors:Selection", sel_bg, mix(sel_bg, PANEL, 0.3), TEXT, a, inactive=mix(TEXT, sel_bg, 0.3)),
        section("Colors:Tooltip", VOID, PANEL, DATA, a),
        section("Colors:View", DEEP, mix(DEEP, STEEL, 0.5), TEXT, a),
        section("Colors:Window", PANEL, STEEL, TEXT, a),
        f"""[General]
ColorScheme=KyberOS{title}
Name=KyberOS {title} Crystal
shadeSortColumn=true

[KDE]
contrast=6

[WM]
activeBackground={kde(PANEL)}
activeBlend={kde(a)}
activeForeground={kde(TEXT)}
inactiveBackground={kde(VOID)}
inactiveBlend={kde(EDGE)}
inactiveForeground={kde(FAINT)}
""",
    ]
    return "\n".join(parts)


def generate(out):
    d = out / "color-schemes"
    d.mkdir(parents=True, exist_ok=True)
    for crystal in CRYSTALS:
        (d / f"KyberOS{crystal.capitalize()}.colors").write_text(scheme(crystal))
