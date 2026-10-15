"""GTK 3/4 theme + Muffin (metacity-1) window borders, one per crystal: KyberOS-<Crystal>.

Base: the vendored Mint-Y-Dark compiled CSS (src/cinnamon/base/mint-y, GPL-3.0+), recoloured
onto the KyberOS palette by recolor.py, with its PNG check/radio/switch images swapped for
generated SVGs. On top sits the KyberOS layer: chamfered plates (border-image), saber
progress bars, accent lines, typography. The Cinnamon shell theme is gen_cinnamon.py.
"""
from pathlib import Path
import re

from palette import *
from recolor import recolor
from gen_aurorae import glyph, plate as btn_plate, BTN_W, BTN_H

BASE = Path(__file__).resolve().parent.parent / "src" / "cinnamon" / "base" / "mint-y"


def svg(w, h, body):
    return (f'<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" '
            f'width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n{body}\n</svg>\n')


def chamfer(x, y, w, h, k, fill, fop=1.0, stroke=None, sop=1.0, sw=1.0, corners=("tl", "br")):
    """Rectangle with 45-degree cuts on the given corners, stroke drawn inside the box."""
    i = sw / 2 if stroke else 0
    x0, y0, x1, y1 = x + i, y + i, x + w - i, y + h - i
    kt = k if "tl" in corners else 0
    kr = k if "tr" in corners else 0
    kb = k if "br" in corners else 0
    kl = k if "bl" in corners else 0
    pts = [(x0, y0 + kt), (x0 + kt, y0), (x1 - kr, y0), (x1, y0 + kr), (x1, y1 - kb), (x1 - kb, y1), (x0 + kl, y1), (x0, y1 - kl)]
    p = " ".join(f"{a:.2f},{b:.2f}" for a, b in pts)
    st = f";stroke:{stroke};stroke-opacity:{sop};stroke-width:{sw}" if stroke else ""
    return f'<polygon points="{p}" style="fill:{fill};fill-opacity:{fop}{st}"/>'


# ---- check / radio / switch images (names as the Mint-Y CSS expects, .png -> .svg) ----

def check_assets(a):
    out = {}
    variants = {
        # variant: (box fill, box border, mark colour, opacity)
        "dark": (VOID, BEVEL, a, 1.0),
        "insensitive-dark": (VOID, BEVEL, FAINT, 0.5),
        "selected": (VOID, TEXT, TEXT, 1.0),
        "insensitive-selected": (VOID, TEXT, TEXT, 0.5),
    }
    for mark in ("checked", "unchecked", "mixed"):
        for var, (fill, edge, col, op) in variants.items():
            on = mark != "unchecked"
            box_edge = (a if var == "dark" else edge) if on else edge
            box = chamfer(1, 1, 14, 14, 3, fill, 1, box_edge, 1, 1.2)
            m = ""
            if mark == "checked":
                m = f'<path d="M4.2 8.2 L7 11 L12 5" style="fill:none;stroke:{col};stroke-width:2;stroke-linecap:square"/>'
            elif mark == "mixed":
                m = f'<rect x="4" y="7" width="8" height="2" style="fill:{col}"/>'
            out[f"checkbox-{mark}-{var}"] = svg(16, 16, f'<g opacity="{op}">{box}{m}</g>')
            # radio = diamond, lit core when checked
            d = f'<polygon points="8,1.2 14.8,8 8,14.8 1.2,8" style="fill:{fill};stroke:{box_edge};stroke-width:1.2"/>'
            core = ""
            if mark == "checked":
                core = f'<polygon points="8,4.6 11.4,8 8,11.4 4.6,8" style="fill:{col}"/>'
            elif mark == "mixed":
                core = f'<rect x="5" y="7" width="6" height="2" style="fill:{col}"/>'
            out[f"radio-{mark}-{var}"] = svg(16, 16, f'<g opacity="{op}">{d}{core}</g>')
    out["checkbox-selectionmode-dark"] = out["checkbox-unchecked-dark"]
    out["checkbox-checked-selectionmode-dark"] = out["checkbox-checked-dark"]

    def switch(on, edge, op):
        track = chamfer(1, 3, 50, 18, 5, VOID if not on else mix(VOID, a, 0.25), 1, a if on else edge, 1, 1.2)
        blade = f'<rect x="6" y="11" width="22" height="2" style="fill:{a};fill-opacity:0.9"/>' if on else ""
        kx = 30 if on else 4
        knob = chamfer(kx, 5, 18, 14, 4, STEEL if not on else "#eaf6ff", 1, EDGE if not on else a, 1, 1)
        return svg(52, 24, f'<g opacity="{op}">{track}{blade}{knob}</g>')

    for var, edge, op in (("dark", BEVEL, 1), ("header-dark", EDGE, 1), ("selected", TEXT, 1),
                          ("insensitive-dark", BEVEL, 0.5), ("insensitive-header-dark", EDGE, 0.5),
                          ("insensitive-selected", TEXT, 0.5)):
        out[f"switch-{var}"] = switch(False, edge, op)
        out[f"switch-active-{var}"] = switch(True, edge, op)
    out["pane-separator"] = svg(24, 2, f'<rect width="24" height="2" style="fill:{BEVEL}"/><rect x="9" width="6" height="2" style="fill:{a}"/>')
    out["pane-separator-vertical"] = svg(2, 24, f'<rect width="2" height="24" style="fill:{BEVEL}"/><rect y="9" width="2" height="6" style="fill:{a}"/>')
    out["thumbnail-frame"] = svg(24, 24, chamfer(0.5, 0.5, 23, 23, 4, PANEL, 1, BEVEL))
    return out


# ---- chamfered plates for border-image ----

PLATE = 24      # image size
SLICE = 6       # border-image slice / width


def plate_assets(a):
    p = lambda fill, fop, edge, sop=1.0, diag=False: svg(PLATE, PLATE, chamfer(0, 0, PLATE, PLATE, 5, fill, fop, edge, sop, 1)
        + (f'<polygon points="0,5 5,0 6.4,1.4 1.4,6.4" style="fill:{a}"/>' if diag else ""))
    return {
        "btn-normal": p(STEEL, 1, BEVEL),
        "btn-hover": p(RAISED, 1, a, 0.8, True),
        "btn-active": p(mix(STEEL, a, 0.35), 1, a, 1, True),
        "btn-checked": p(mix(STEEL, a, 0.25), 1, a, 1, True),
        "btn-disabled": p(STEEL, 0.5, BEVEL, 0.5),
        "btn-suggested": p(mix(PANEL, a, 0.55), 1, a, 1, True),
        "btn-destructive": p(mix(PANEL, ALERT, 0.5), 1, ALERT, 1, True),
        "entry-normal": svg(PLATE, PLATE, chamfer(0, 0, PLATE, PLATE, 4, VOID, 1, BEVEL, 1, 1, ("br",))),
        "entry-focus": svg(PLATE, PLATE, chamfer(0, 0, PLATE, PLATE, 4, VOID, 1, a, 1, 1, ("br",))
                           + f'<rect x="0" y="{PLATE-2}" width="{PLATE-4}" height="2" style="fill:{a}"/>'),
        "entry-disabled": svg(PLATE, PLATE, chamfer(0, 0, PLATE, PLATE, 4, VOID, 0.5, BEVEL, 0.5, 1, ("br",))),
        "menu": p(PANEL, 0.98, BEVEL, 1, True),
        "tooltip": svg(PLATE, PLATE, chamfer(0, 0, PLATE, PLATE, 5, VOID, 0.96, a, 0.7, 1)),
        "tab-checked": svg(PLATE, PLATE, chamfer(0, 0, PLATE, PLATE, 5, STEEL, 1, BEVEL, 1, 1, ("tl",))
                           + f'<rect x="5" y="0" width="{PLATE-5}" height="2" style="fill:{a}"/>'),
    }


def border_image(name, gtk4):
    # GTK 4 needs 'fill' to paint the centre slice; GTK 3 always paints it and rejects 'fill'
    fill = " fill" if gtk4 else ""
    return (f'border-image: url("assets/{name}.svg") {SLICE}{fill} / {SLICE}px stretch; '
            f'border-color: transparent; background: none; box-shadow: none;')


def wbtn(state, only=None):
    """Selector list for every window button class in GTK 3 title bars and GTK 4 windowcontrols."""
    kinds = [only] if only else ["close", "maximize", "minimize"]
    sels = []
    for k in kinds:
        sels += [f"headerbar button.titlebutton.{k}{state}", f".titlebar button.titlebutton.{k}{state}",
                 f"windowcontrols button.{k}{state}"]
    return ", ".join(sels)


def kyber_layer(a, gtk4):
    bi = lambda n: border_image(n, gtk4)
    glow = f"0 0 6px {a}"
    return f"""
/* ==== KyberOS layer ================================================= */
* {{ outline-color: alpha({a}, 0.6); }}
headerbar, .titlebar {{ background: {STEEL}; border-bottom: 1px solid alpha({a}, 0.45); box-shadow: none; }}
headerbar .title, .titlebar .title {{ font-family: "{FONTS['title']}"; font-weight: 600; letter-spacing: 2px; }}
headerbar .subtitle {{ font-family: "{FONTS['mono']}"; color: {DIM}; }}

button:not(.flat):not(.titlebutton):not(.circular) {{ {bi("btn-normal")} }}
button:not(.flat):not(.titlebutton):not(.circular):hover {{ {bi("btn-hover")} }}
button:not(.flat):not(.titlebutton):not(.circular):active,
button:not(.flat):not(.titlebutton):not(.circular):checked {{ {bi("btn-active")} }}
button:not(.flat):not(.titlebutton):not(.circular):disabled {{ {bi("btn-disabled")} }}
button.suggested-action:not(.flat) {{ {bi("btn-suggested")} color: #ffffff; }}
button.destructive-action:not(.flat) {{ {bi("btn-destructive")} color: #ffffff; }}
button.flat:hover {{ background: alpha({a}, 0.14); }}
button.flat:checked, button.flat:active {{ background: alpha({a}, 0.26); }}

entry {{ {bi("entry-normal")} }}
entry:focus, entry:focus-within {{ {bi("entry-focus")} }}
entry:disabled {{ {bi("entry-disabled")} }}

progressbar trough {{ background: {VOID}; border: 1px solid {BEVEL}; border-radius: 1px; }}
progressbar progress {{
  border-radius: 1px; border: 1px solid {a};
  background-image: linear-gradient(to bottom, {a}, #f2fbff 40%, #f2fbff 60%, {a});
  box-shadow: {glow}; }}
levelbar block.filled {{ background: {a}; box-shadow: {glow}; }}
scale highlight {{ background: {a}; box-shadow: {glow}; }}
scale slider {{ border-radius: 1px; background: {STEEL}; border: 1px solid {a}; }}

notebook > header tab:checked {{ {bi("tab-checked")} }}
notebook > header tab label {{ font-family: "{FONTS['heading']}"; font-size: 0.85em; letter-spacing: 1px; }}

tooltip, tooltip.background {{ {bi("tooltip")} color: {TEXT}; }}
tooltip label {{ font-family: "{FONTS['mono']}"; }}

row:selected, treeview.view:selected, iconview:selected, flowboxchild:selected {{
  background-color: alpha({a}, 0.32); color: {TEXT}; box-shadow: inset 2px 0 {a}; }}
scrollbar slider {{ border-radius: 0; }}

/* window buttons: square, lit on hover, close goes red. Mint-Y styles each button class
   (.close/.maximize/.minimize, incl. :backdrop) with a radial-gradient disc, so match that. */
{wbtn("")} {{ border-radius: 0; border: none; box-shadow: none; background: none; background-image: none;
  color: {TEXT}; min-width: 26px; min-height: 22px; padding: 0 3px; margin: 0 1px; }}
{wbtn(":backdrop")} {{ background: none; background-image: none; color: {FAINT}; }}
{wbtn(":hover")} {{ background-image: none; background-color: alpha({a}, 0.22); box-shadow: inset 0 0 0 1px {a}; color: {a}; }}
{wbtn(":active")} {{ background-image: none; background-color: alpha({a}, 0.4); color: #ffffff; }}
{wbtn(":hover", "close")}, {wbtn(":active", "close")} {{ background-image: none; background-color: {ALERT}; box-shadow: none; color: #ffffff; }}
windowcontrols button > image, headerbar button.titlebutton > image {{
  background: none; background-color: transparent; border-radius: 0; box-shadow: none; color: inherit; }}
scrollbar slider:hover {{ background: {a}; }}
"""


def gtk3_extra(a):
    bi = lambda n: border_image(n, False)
    return f"""
menu, .menu, .context-menu {{ {bi("menu")} padding: 4px; }}
popover.background {{ {bi("menu")} }}
menuitem:hover, .menuitem:hover {{ background: alpha({a}, 0.28); color: {TEXT}; box-shadow: inset 2px 0 {a}; }}
.csstage {{ background: {VOID}; }}
.csstage .clock {{ color: {TEXT}; text-shadow: 0 0 12px alpha({a}, 0.6); }}
.csstage .unlockbox {{ color: {TEXT}; font-family: "{FONTS['mono']}"; }}
.csstage .passwordentry {{ border-radius: 0; border: 1px solid {a}; background-color: alpha({VOID}, 0.85);
  color: {DATA}; font-family: "{FONTS['mono']}"; box-shadow: inset 0 -2px {a}; }}
.csstage .auth-message {{ color: {ALERT}; font-family: "{FONTS['mono']}"; letter-spacing: 2px; }}
.csstage .caps-message {{ color: {AMBER}; font-family: "{FONTS['mono']}"; }}
.csstage .toppanel {{ background-image: none; background-color: alpha({PANEL}, 0.85); border-color: alpha({a}, 0.5); }}
.csstage .framedimage {{ border-radius: 0; border-color: {a}; }}
"""


def gtk4_extra(a):
    bi = lambda n: border_image(n, True)
    return f"""
popover > contents, popover.menu > contents {{ {bi("menu")} }}
popover modelbutton:hover {{ background: alpha({a}, 0.28); box-shadow: inset 2px 0 {a}; }}
"""


def build_css(base_name, a, gtk4):
    css = recolor((BASE / base_name).read_text(), a)
    css = re.sub(r'-gtk-scaled\(url\("assets/([a-z0-9-]+)\.png"\),\s*url\("assets/\1@2\.png"\)\)',
                 r'url("assets/\1.svg")', css)
    css = re.sub(r'url\("assets/([a-z0-9-]+)(@2)?\.png"\)', r'url("assets/\1.svg")', css)
    header = ("/* KyberOS GTK theme. Base: Mint-Y-Dark (linuxmint/mint-themes, GPL-3.0+), recoloured;\n"
              "   generated by build/gen_gtk.py, do not edit. */\n")
    return header + css + kyber_layer(a, gtk4) + (gtk4_extra(a) if gtk4 else gtk3_extra(a))


# ---- Muffin / metacity-1 ----

def metacity(a):
    title_h = 28
    def frame_geom(name, has_title=True):
        return f"""<frame_geometry name="{name}" title_scale="medium" rounded_top_left="false" rounded_top_right="false" {'' if has_title else 'has_title="false"'}>
  <distance name="left_width" value="1"/><distance name="right_width" value="1"/><distance name="bottom_height" value="2"/>
  <distance name="left_titlebar_edge" value="10"/><distance name="right_titlebar_edge" value="4"/>
  <distance name="title_vertical_pad" value="6"/><aspect_ratio name="button" value="{BTN_W/BTN_H:.3f}"/>
  <border name="title_border" left="10" right="10" top="3" bottom="3"/><border name="button_border" left="1" right="1" top="3" bottom="3"/>
</frame_geometry>"""

    def title_ops(name, line, text):
        return f"""<draw_ops name="{name}">
  <rectangle color="{STEEL}" x="0" y="0" width="width" height="height" filled="true"/>
  <line color="{line}" x1="0" y1="height-1" x2="width" y2="height-1" width="2"/>
  <line color="{a if line == a else BEVEL}" x1="0" y1="8" x2="8" y2="0" width="2"/>
  <title color="{text}" x="(width - title_width) / 2 `max` 4" y="(height - title_height) / 2 `max` 0"/>
</draw_ops>"""

    btns = ""
    for kind in ("close", "maximize", "minimize", "restore"):
        for state in ("normal", "prelight", "pressed"):
            for foc in ("focused", "unfocused"):
                btns += f'<draw_ops name="btn_{kind}_{state}_{foc}"><image filename="button-{kind}-{state}-{foc}.svg" x="0" y="0" width="width" height="height"/></draw_ops>\n'

    def style(name, foc, line, text):
        b = "".join(
            f'<button function="{fn}" state="{st}" draw_ops="btn_{kind}_{st}_{foc}"/>'
            for fn, kind in (("close", "close"), ("maximize", "maximize"), ("minimize", "minimize"))
            for st in ("normal", "prelight", "pressed"))
        others = "".join(f'<button function="{fn}" state="{st}"><draw_ops/></button>'
                         for fn in ("menu", "shade", "unshade", "above", "unabove", "stick", "unstick")
                         for st in ("normal", "prelight", "pressed"))
        return f"""<frame_style name="{name}" geometry="normal">
  <piece position="entire_background"><draw_ops><rectangle color="{PANEL}" x="0" y="0" width="width" height="height" filled="true"/>
    <rectangle color="{line if foc == 'focused' else BEVEL}" x="0" y="0" width="width-1" height="height-1" filled="false"/></draw_ops></piece>
  <piece position="titlebar" draw_ops="title_{foc}"/>
  {b}{others}
</frame_style>"""

    return f"""<?xml version="1.0"?>
<metacity_theme>
<info><name>KyberOS</name><author>KyberOS</author><copyright>GPL-3.0-or-later</copyright><description>Imperial console window borders</description></info>
{frame_geom("normal")}
{frame_geom("border", False)}
{title_ops("title_focused", a, TEXT)}
{title_ops("title_unfocused", BEVEL, DIM)}
{btns}
{style("focused", "focused", a, TEXT)}
{style("unfocused", "unfocused", BEVEL, DIM)}
<frame_style name="borderless" geometry="border"><piece position="entire_background"><draw_ops><rectangle color="{BEVEL}" x="0" y="0" width="width-1" height="height-1" filled="false"/></draw_ops></piece></frame_style>
<frame_style_set name="normal">
  <frame focus="yes" state="normal" resize="both" style="focused"/>
  <frame focus="no" state="normal" resize="both" style="unfocused"/>
  <frame focus="yes" state="maximized" style="focused"/>
  <frame focus="no" state="maximized" style="unfocused"/>
  <frame focus="yes" state="shaded" style="focused"/>
  <frame focus="no" state="shaded" style="unfocused"/>
  <frame focus="yes" state="maximized_and_shaded" style="focused"/>
  <frame focus="no" state="maximized_and_shaded" style="unfocused"/>
</frame_style_set>
<frame_style_set name="border">
  <frame focus="yes" state="normal" resize="both" style="borderless"/>
  <frame focus="no" state="normal" resize="both" style="borderless"/>
  <frame focus="yes" state="maximized" style="borderless"/>
  <frame focus="no" state="maximized" style="borderless"/>
  <frame focus="yes" state="shaded" style="borderless"/>
  <frame focus="no" state="shaded" style="borderless"/>
  <frame focus="yes" state="maximized_and_shaded" style="borderless"/>
  <frame focus="no" state="maximized_and_shaded" style="borderless"/>
</frame_style_set>
<window type="normal" style_set="normal"/>
<window type="dialog" style_set="normal"/>
<window type="modal_dialog" style_set="normal"/>
<window type="menu" style_set="normal"/>
<window type="utility" style_set="normal"/>
<window type="border" style_set="border"/>
<window type="attached" style_set="border"/>
</metacity_theme>
"""


def metacity_buttons(a):
    out = {}
    for kind in ("close", "maximize", "minimize", "restore"):
        danger = kind == "close"
        hot = ALERT if danger else a
        for foc in ("focused", "unfocused"):
            base = TEXT if foc == "focused" else FAINT
            states = {
                "normal": ("", base),
                "prelight": (btn_plate(hot, 0.85 if danger else 0.22, hot), "#ffffff" if danger else a),
                "pressed": (btn_plate(hot, 1 if danger else 0.4, hot), "#ffffff"),
            }
            for st, (pl, col) in states.items():
                out[f"button-{kind}-{st}-{foc}"] = svg(BTN_W, BTN_H, pl + glyph(kind, col))
    return out


def index_theme(cap):
    return f"""[Desktop Entry]
Type=X-GNOME-Metatheme
Name=KyberOS-{cap}
Comment=Imperial console theme (KyberOS), {cap} kyber crystal
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=KyberOS-{cap}
MetacityTheme=KyberOS-{cap}
IconTheme=KyberOS
CursorTheme=KyberOS-{cap}
ButtonLayout=:minimize,maximize,close
"""


def generate(out):
    for crystal, a in CRYSTALS.items():
        cap = crystal.capitalize()
        t = out / "themes" / f"KyberOS-{cap}"
        assets = {**check_assets(a), **plate_assets(a)}
        for ver, base, gtk4 in (("gtk-3.0", "gtk-3.0.css", False), ("gtk-4.0", "gtk-4.0.css", True)):
            d = t / ver
            (d / "assets").mkdir(parents=True, exist_ok=True)
            css = build_css(base, a, gtk4)
            (d / "gtk.css").write_text(css)
            (d / "gtk-dark.css").write_text(css)
            for name, body in assets.items():
                (d / "assets" / f"{name}.svg").write_text(body)
        m = t / "metacity-1"
        m.mkdir(parents=True, exist_ok=True)
        (m / "metacity-theme-3.xml").write_text(metacity(a))
        for name, body in metacity_buttons(a).items():
            (m / f"{name}.svg").write_text(body)
        (t / "index.theme").write_text(index_theme(cap))
