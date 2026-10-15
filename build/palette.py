"""KyberOS design tokens. Every generator reads colours from here."""

# Imperial console neutrals: cold steel over near-black.
VOID = "#06080b"      # deepest background (wallpaper, terminal)
DEEP = "#0c0f13"      # view backgrounds (lists, editors)
PANEL = "#12161c"     # window / panel background
STEEL = "#1a2029"     # buttons, raised surfaces
RAISED = "#232b36"    # hover, alternate rows
BEVEL = "#36414f"     # 1px frame lines
EDGE = "#566476"      # strong frame lines, inactive decorations
TEXT = "#d6dee8"      # primary text
DIM = "#8793a3"       # secondary text
FAINT = "#566070"     # disabled text

# Readout colours from the films' consoles.
DATA = "#a6f2c4"      # phosphor green-white data
AMBER = "#ffb02e"     # caution, neutral messages
ALERT = "#ff3b2f"     # alarms, negative
OK = "#3ee88a"        # positive

# Kyber crystal accents (the user-pickable accent).
CRYSTALS = {
    "blue": "#33b5ff",
    "green": "#3ef08a",
    "red": "#ff2d3f",
    "purple": "#b264ff",
    "yellow": "#ffd23c",
    "white": "#e2f4ff",
}
DEFAULT_CRYSTAL = "blue"

FONTS = {
    "ui": "Exo 2",
    "title": "Orbitron",
    "heading": "Michroma",
    "mono": "Share Tech Mono",
}


def rgb(hex_colour):
    h = hex_colour.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def kde(hex_colour):
    """'#rrggbb' -> 'r,g,b' as KDE config files want it."""
    return ",".join(str(c) for c in rgb(hex_colour))


def mix(a, b, t):
    """Blend colour a toward b by t (0..1)."""
    ra, rb = rgb(a), rgb(b)
    return "#" + "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(ra, rb))


def on_accent(accent):
    """Readable text colour on top of an accent fill."""
    r, g, b = rgb(accent)
    return VOID if (0.299 * r + 0.587 * g + 0.114 * b) > 140 else TEXT
