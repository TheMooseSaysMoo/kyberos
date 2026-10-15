"""Cinnamon shell theme (panel, menus, Alt+Tab, dialogs, OSD), one per crystal.

Writes dist/themes/KyberOS-<Crystal>/cinnamon/: the vendored Mint-Y-Dark cinnamon.css
recoloured onto the palette, its SVG assets recoloured, plus the KyberOS layer below.
St (Cinnamon's toolkit) has no alpha() so translucent colours are spelled out as rgba().
"""
from pathlib import Path
import re
import shutil

from palette import *
from recolor import recolor, _recolor_values

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / "src" / "cinnamon" / "base" / "mint-y"
KWIN_SHADERS = ROOT / "src" / "kwin" / "effects" / "kyberos_open" / "contents" / "shaders"


def cogl_snippet(src):
    """KWin fragment shader (GLSL 1.40, texture()/fragColor) -> Cogl snippet for Cinnamon.GLSLEffect.

    The body becomes a function; Cogl's GLSL 1.10 names replace KWin's. One source of truth
    for both desktops. Returns 'declarations //@@CODE@@ code'.
    """
    body = src
    for line in ("uniform sampler2D sampler;", "uniform vec4 modulation;", "uniform int textureWidth;",
                 "uniform int textureHeight;", "in vec2 texcoord0;", "out vec4 fragColor;"):
        body = body.replace(line + "\n", "")
    body = (body.replace("float(textureWidth)", "uSize.x").replace("float(textureHeight)", "uSize.y")
                .replace("texture(sampler,", "texture2D(uTexture,").replace("fragColor =", "return")
                .replace("modulation", "cogl_color_in").replace("void main()", "vec4 kyb_main(vec2 texcoord0)"))
    decl = "uniform sampler2D uTexture;   /* unit 0: the window, as GLSLEffect paints it */\nuniform vec2 uSize;\n" + body
    return decl + "\n//@@CODE@@\ncogl_color_out = kyb_main(cogl_tex_coord_in[0].st);\n"


def rgba(c, a):
    r, g, b = rgb(c)
    return f"rgba({r}, {g}, {b}, {a})"


def kyber_layer(a):
    return f"""
/* ==== KyberOS layer ================================================= */
stage {{ font-family: "{FONTS['ui']}", sans-serif; color: {TEXT}; }}

/* panels: steel strip with a lit edge */
#panel {{ height: 34px; font-weight: normal; }}
.panel-top {{ background-color: {rgba(PANEL, 0.94)}; border-bottom: 1px solid {rgba(a, 0.55)}; box-shadow: 0 1px 0 {rgba(VOID, 0.8)}; }}
.panel-bottom {{ background-color: {rgba(PANEL, 0.94)}; border-top: 1px solid {rgba(a, 0.55)}; }}
.panel-left {{ background-color: {rgba(PANEL, 0.94)}; border-right: 1px solid {rgba(a, 0.55)}; }}
.panel-right {{ background-color: {rgba(PANEL, 0.94)}; border-left: 1px solid {rgba(a, 0.55)}; }}
.applet-box {{ border-radius: 0; }}
.applet-box:hover, .applet-box:checked {{ background-color: {rgba(a, 0.16)}; color: {TEXT}; }}
.applet-label {{ font-family: "{FONTS['heading']}"; font-size: 0.9em; }}
.grouped-window-list-item-box, .window-list-item-box {{ border-radius: 0; }}
.grouped-window-list-item-box:hover, .window-list-item-box:hover {{ background-color: {rgba(a, 0.14)}; }}
.grouped-window-list-item-box:focus, .grouped-window-list-item-box:checked,
.window-list-item-box:focus, .window-list-item-box:checked {{ background-color: {rgba(a, 0.22)}; border-color: {a}; }}

/* menus and popups: square steel plates, lit top edge */
.menu, .popup-menu-boxpointer {{ border-radius: 0; background-color: {rgba(PANEL, 0.98)}; border: 1px solid {BEVEL}; color: {TEXT}; }}
.menu-top, .menu-bottom, .menu-left, .menu-right {{ border-radius: 0; }}
.popup-menu-item:active, .popup-menu-item.selected {{ background-color: {rgba(a, 0.26)}; border-left: 2px solid {a}; color: {TEXT}; border-radius: 0; }}
.popup-separator-menu-item {{ background: none; border-bottom: 1px solid {BEVEL}; }}
.menu-favorites-box {{ background-color: {rgba(VOID, 0.6)}; border: 1px solid {BEVEL}; border-radius: 0; }}
.menu-favorites-button:hover, .menu-application-button-selected, .menu-category-button-selected {{
  background-color: {rgba(a, 0.24)}; border-radius: 0; color: {TEXT}; }}
.menu-application-button-label, .menu-category-button-label {{ font-family: "{FONTS['ui']}"; }}
StEntry, .menu-search-box StEntry, #menu-search-entry {{ border-radius: 0; background-color: {VOID}; border: 1px solid {BEVEL};
  font-family: "{FONTS['mono']}"; color: {DATA}; caret-color: {a}; selection-background-color: {rgba(a, 0.5)}; }}
StEntry:focus, #menu-search-entry:focus {{ border: 1px solid {a}; }}

#Tooltip {{ background-color: {rgba(VOID, 0.96)}; border: 1px solid {rgba(a, 0.7)}; border-radius: 0;
  color: {TEXT}; font-family: "{FONTS['mono']}"; padding: 6px 10px; }}

/* Alt+Tab: SELECT TARGET, amber lock on the chosen window */
.switcher-list {{ background-color: {rgba(VOID, 0.94)}; border: 1px solid {BEVEL}; border-top: 2px solid {a}; border-radius: 0; }}
.switcher-list .item-box {{ border-radius: 0; }}
.switcher-list .item-box:outlined {{ border: 1px solid {rgba(a, 0.6)}; }}
.switcher-list .item-box:selected {{ background-color: {rgba(a, 0.16)}; border: 2px solid {AMBER}; }}
.switcher-list .thumbnail-box StLabel, .switcher-list .item-box StLabel {{ font-family: "{FONTS['mono']}"; color: {DATA}; }}

/* calendar */
.calendar {{ border-radius: 0; }}
.calendar-month-label {{ font-family: "{FONTS['heading']}"; letter-spacing: 2px; color: {a}; }}
.calendar-today {{ background-color: {rgba(a, 0.3)}; border: 1px solid {a}; border-radius: 0; color: {TEXT}; }}
.calendar-day-base:hover {{ background-color: {rgba(a, 0.18)}; border-radius: 0; }}

/* dialogs (logout/shutdown "POWER SYSTEMS", run, polkit): Cinnamon 6 uses .dialog / .dialog-button.
   Buttons stay at normal weight: St measures variable fonts at regular weight, so bold ellipsizes. */
.dialog, .cinnamon-modal-dialog, .modal-dialog {{ background-color: {rgba(VOID, 0.96)}; border: 1px solid {BEVEL};
  border-top: 2px solid {a}; border-radius: 0; color: {TEXT}; }}
.message-dialog-content .message-dialog-title, .dialog .confirm-dialog-title, .end-session-dialog-subject,
.dialog-header {{ font-family: "{FONTS['title']}"; font-weight: normal; letter-spacing: 3px; color: {a}; }}
.dialog .dialog-button, .dialog .dialog-button:destructive-action, .dialog .dialog-button:default,
.modal-dialog-button {{ border-radius: 0; background-color: {STEEL}; border: 1px solid {BEVEL};
  font-family: "{FONTS['ui']}"; font-weight: normal; letter-spacing: 1px; color: {TEXT}; padding: 10px 22px; }}
.dialog .dialog-button:hover, .modal-dialog-button:hover {{ background-color: {RAISED}; border: 1px solid {a}; color: {TEXT}; }}
.dialog .dialog-button:focus, .modal-dialog-button:focus {{ border: 1px solid {a}; }}
.dialog .dialog-button:active, .dialog .dialog-button:checked {{ background-color: {rgba(a, 0.35)}; }}
.dialog .dialog-button:default {{ border: 1px solid {AMBER}; color: {AMBER}; }}
.dialog .dialog-button:destructive-action {{ border: 1px solid {ALERT}; color: {ALERT}; }}
.dialog .dialog-button:destructive-action:hover {{ background-color: {ALERT}; color: #ffffff; }}

/* notifications and OSD */
.notification, #notification {{ border-radius: 0; background-color: {rgba(VOID, 0.96)}; border: 1px solid {BEVEL}; border-left: 3px solid {a}; }}
#notification .notification-header, .notification-title {{ font-family: "{FONTS['heading']}"; color: {a}; }}
.osd-window, .info-osd {{ border-radius: 0; background-color: {rgba(VOID, 0.92)}; border: 1px solid {rgba(a, 0.7)}; }}
.osd-window .level, .osd-window .level-bar {{ border-radius: 0; }}
.osd-window .level-bar {{ background-color: {a}; box-shadow: 0 0 6px {a}; }}

/* workspace switcher + expo */
.workspace-switcher .workspace-button {{ border-radius: 0; }}
.workspace-switcher .workspace-button:outlined {{ background-color: {rgba(a, 0.35)}; border-bottom: 2px solid {a}; }}
.workspace-graph {{ border-radius: 0; }}
.workspace-graph:active {{ border: 1px solid {a}; }}

/* sliders + switches in menus (sound, brightness) */
.slider {{ -slider-active-background-color: {a}; -slider-border-radius: 0; -slider-handle-radius: 4px; }}
.toggle-switch-us, .toggle-switch-intl {{ border-radius: 0; }}
"""


def generate(out):
    # applets + extensions, with the effect shaders generated from the KWin ones
    cin = out / "cinnamon"
    if cin.exists():
        shutil.rmtree(cin)
    for kind in ("applets", "extensions"):
        shutil.copytree(ROOT / "src" / "cinnamon" / kind, cin / kind)
    # backdrop runners + the shared Backdrop.qml / scenes / images from the Plasma wallpaper
    bd = cin / "backdrop"
    shutil.copytree(ROOT / "src" / "cinnamon" / "backdrop", bd)
    wp = out / "plasma" / "wallpapers" / "org.kyberos.tactical" / "contents"
    if not wp.exists():   # partial build: take the sources
        wp = ROOT / "src" / "plasma" / "wallpapers" / "org.kyberos.tactical" / "contents"
    (bd / "ui").mkdir()
    shutil.copy2(wp / "ui" / "Backdrop.qml", bd / "ui" / "Backdrop.qml")
    shutil.copytree(wp / "ui" / "scenes", bd / "ui" / "scenes")
    shutil.copytree(wp / "images", bd / "images")
    sh = cin / "extensions" / "kyberos-effects@kyberos" / "shaders"
    sh.mkdir(parents=True)
    for name in ("projector", "hologram", "powerdown"):
        (sh / f"{name}.glsl").write_text(cogl_snippet((KWIN_SHADERS / f"{name}.frag").read_text()))

    css_base = (BASE / "cinnamon.css").read_text()
    for crystal, a in CRYSTALS.items():
        cap = crystal.capitalize()
        d = out / "themes" / f"KyberOS-{cap}" / "cinnamon"
        if d.exists():
            shutil.rmtree(d)
        d.mkdir(parents=True)
        header = ("/* KyberOS Cinnamon theme. Base: Mint-Y-Dark (linuxmint/mint-themes, GPL-3.0+), recoloured;\n"
                  "   generated by build/gen_cinnamon.py, do not edit. */\n")
        (d / "cinnamon.css").write_text(header + recolor(css_base, a) + kyber_layer(a))
        for src in (BASE / "cinnamon-assets").rglob("*"):
            if src.is_dir():
                continue
            dst = d / src.relative_to(BASE / "cinnamon-assets")
            dst.parent.mkdir(parents=True, exist_ok=True)
            if src.suffix == ".svg":
                dst.write_text(_recolor_values(src.read_text(), a))   # SVG: no selectors, recolour everything
            else:
                shutil.copy2(src, dst)
