"""Kvantum widget theme 'KyberOS-<Crystal>' for ordinary Qt/KDE apps.

Chamfered steel buttons, fields, tabs, menus and scrollbars; diamond radio
buttons; saber progress bars. Element names follow Kvantum's convention:
'<element>-<state>' is the fill and '<element>-<state>-<piece>' the frame.
The section layout of the .kvconfig is modelled on Kvantum's KvFlat (GPL).
"""
from palette import *
from svgframe import Frame

STATES = ("normal", "focused", "pressed", "toggled", "disabled")


def frames(a):
    """element -> {state: Frame kwargs} for every framed widget."""
    fill = lambda c, o=1: (c, o)
    clear = ("#000000", 0.002)
    btn = dict(corner=4, chamfer=3)
    f = {}
    f["button"] = {
        "normal": dict(**btn, fill=fill(STEEL), border=BEVEL),
        "focused": dict(**btn, fill=fill(RAISED), border=a, diag=a),
        "pressed": dict(**btn, fill=fill(mix(STEEL, a, 0.35)), border=a, diag=a),
        "toggled": dict(**btn, fill=fill(mix(STEEL, a, 0.25)), border=a, diag=a),
        "disabled": dict(**btn, fill=fill(STEEL, 0.5), border=(BEVEL, 0.5)),
    }
    f["tbutton"] = {
        "normal": dict(**btn, fill=clear),
        "focused": dict(**btn, fill=fill(a, 0.14), border=(a, 0.5), diag=a),
        "pressed": dict(**btn, fill=fill(a, 0.3), border=a, diag=a),
        "toggled": dict(**btn, fill=fill(a, 0.22), border=(a, 0.8), diag=a),
        "disabled": dict(**btn, fill=clear),
    }
    f["lineedit"] = {
        "normal": dict(corner=4, fill=fill(VOID), border=BEVEL),
        "focused": dict(corner=4, fill=fill(VOID), border=a, bars={"bottom": (a, 2)}),
        "disabled": dict(corner=4, fill=fill(VOID, 0.5), border=(BEVEL, 0.5)),
    }
    f["itemview"] = {
        "normal": dict(corner=2, fill=clear),
        "focused": dict(corner=2, fill=fill(a, 0.14)),
        "pressed": dict(corner=2, fill=fill(a, 0.32), border=(a, 0.6)),
        "toggled": dict(corner=2, fill=fill(a, 0.26), border=(a, 0.5)),
    }
    f["menu"] = {"normal": dict(corner=4, chamfer=3, fill=fill(PANEL, 0.98), border=BEVEL, diag=a)}
    for el in ("menuitem", "menubaritem"):
        f[el] = {
            "normal": dict(corner=2, fill=clear),
            "focused": dict(corner=2, fill=fill(a, 0.26), border=(a, 0.5)),
            "pressed": dict(corner=2, fill=fill(a, 0.36), border=a),
            "toggled": dict(corner=2, fill=fill(a, 0.3), border=(a, 0.7)),
        }
    f["scrollbargroove"] = {"normal": dict(corner=3, fill=fill(VOID, 0.6))}
    f["scrollbarslider"] = {
        "normal": dict(corner=3, fill=fill(EDGE)),
        "focused": dict(corner=3, fill=fill(mix(EDGE, a, 0.6))),
        "pressed": dict(corner=3, fill=fill(a)),
        "disabled": dict(corner=3, fill=fill(EDGE, 0.4)),
    }
    f["ss"] = {
        "normal": dict(corner=6, fill=fill(EDGE, 0.85)),
        "focused": dict(corner=6, fill=fill(a, 0.85)),
        "pressed": dict(corner=6, fill=fill(a)),
    }
    f["progress"] = {"normal": dict(corner=3, fill=fill(VOID, 0.85), border=BEVEL)}
    # saber blade: white-hot core inside a crystal-coloured edge
    f["progress-pattern"] = {
        "normal": dict(corner=3, fill=fill("#f2fbff", 0.95), border=a, border_w=1.5),
        "disabled": dict(corner=3, fill=fill(DIM, 0.6), border=EDGE),
    }
    f["slider"] = {
        "normal": dict(corner=3, fill=fill(VOID), border=BEVEL),
        "toggled": dict(corner=3, fill=fill(a, 0.85), border=a),
        "disabled": dict(corner=3, fill=fill(VOID, 0.5), border=(BEVEL, 0.5)),
    }
    tab = dict(corner=4, chamfer=3, chamfered=("topleft",))
    for el in ("tab", "floating-tab"):
        f[el] = {
            "normal": dict(**tab, fill=fill(STEEL, 0.6), border=(BEVEL, 0.8)),
            "focused": dict(**tab, fill=fill(RAISED), border=BEVEL, diag=a),
            "pressed": dict(**tab, fill=fill(mix(PANEL, a, 0.25)), border=a, diag=a),
            "toggled": dict(**tab, fill=fill(PANEL), border=BEVEL, diag=a, bars={"top": (a, 2)}),
            "disabled": dict(**tab, fill=fill(STEEL, 0.3), border=(BEVEL, 0.4)),
        }
    f["tabframe"] = {"normal": dict(corner=4, fill=fill(PANEL), border=BEVEL)}
    f["group"] = {"normal": dict(corner=4, chamfer=3, fill=fill(PANEL, 0.4), border=BEVEL, diag=a)}
    f["toolbar"] = {"normal": dict(corner=2, fill=fill(PANEL))}
    f["common"] = {
        "normal": dict(corner=4, fill=clear, border=BEVEL),
        "focused": dict(corner=4, fill=clear, border=a),
    }
    f["tooltip"] = {"normal": dict(corner=4, chamfer=3, fill=fill(VOID, 0.97), border=BEVEL, diag=a)}
    f["splitter"] = {"normal": dict(corner=1, fill=clear)}
    return f


def indicators(a):
    """Single-element indicators, each drawn in a 16x16 box: id -> svg body."""
    out = {}
    state_col = {"normal": TEXT, "focused": a, "pressed": a, "toggled": a, "disabled": FAINT}

    def stroke(d, c, w=1.8):
        return f'<path d="{d}" style="fill:none;stroke:{c};stroke-width:{w};stroke-linecap:square;stroke-linejoin:miter"/>'

    chevrons = {"up": "M 4 10 L 8 6 L 12 10", "down": "M 4 6 L 8 10 L 12 6",
                "left": "M 10 4 L 6 8 L 10 12", "right": "M 6 4 L 10 8 L 6 12"}
    for st, c in state_col.items():
        for d, path in chevrons.items():
            out[f"arrow-{d}-{st}"] = stroke(path, c)
            if d in ("left", "right"):
                out[f"menuitem-{d}-{st}"] = stroke(path, c)
        out[f"arrow-plus-{st}"] = stroke("M 8 4 V 12 M 4 8 H 12", c)
        out[f"arrow-minus-{st}"] = stroke("M 4 8 H 12", c)
        out[f"tab-close-{st}"] = stroke("M 5 5 L 11 11 M 11 5 L 5 11", ALERT if st in ("focused", "pressed") else c, 1.6)

    box = "M 2 5 L 5 2 H 14 V 11 L 11 14 H 2 Z"           # chamfered square
    diamond = "M 8 1.5 L 14.5 8 L 8 14.5 L 1.5 8 Z"
    for st in ("normal", "focused", "pressed", "disabled"):
        edge = {"normal": EDGE, "focused": a, "pressed": a, "disabled": BEVEL}[st]
        base = f'<path d="{box}" style="fill:{VOID};stroke:{edge};stroke-width:1.2"/>'
        out[f"checkbox-{st}"] = base
        tick_bg = a if st != "disabled" else EDGE
        out[f"checkbox-checked-{st}"] = (f'<path d="{box}" style="fill:{tick_bg};stroke:{tick_bg};stroke-width:1.2"/>'
                                         + stroke("M 4.5 8.5 L 7 11 L 11.5 5", VOID, 2))
        out[f"checkbox-tristate-{st}"] = base + f'<rect x="4.5" y="7" width="7" height="2" style="fill:{tick_bg}"/>'
        out[f"radio-{st}"] = f'<path d="{diamond}" style="fill:{VOID};stroke:{edge};stroke-width:1.2"/>'
        out[f"radio-checked-{st}"] = (f'<path d="{diamond}" style="fill:{VOID};stroke:{tick_bg};stroke-width:1.2"/>'
                                      f'<path d="M 8 4.5 L 11.5 8 L 8 11.5 L 4.5 8 Z" style="fill:{tick_bg}"/>')
        # slider handle: chamfered plate with a lit centre line
        out[f"slidercursor-{st}"] = (f'<path d="M 3 4 L 5 2 H 13 V 12 L 11 14 H 3 Z" style="fill:{STEEL if st != "pressed" else RAISED};stroke:{edge};stroke-width:1.2"/>'
                                     f'<rect x="7.25" y="4.5" width="1.5" height="7" style="fill:{a if st != "disabled" else EDGE}"/>')
    for st, c in (("normal", EDGE), ("focused", a), ("pressed", a)):
        out[f"grip-{st}"] = stroke("M 5 6 H 11 M 5 8 H 11 M 5 10 H 11", c, 1)
        out[f"splitter-grip-{st}"] = "".join(f'<rect x="7" y="{y}" width="2" height="2" style="fill:{c}"/>' for y in (3, 7, 11))
        out[f"resize-grip-{st}"] = stroke("M 14 6 L 6 14 M 14 10 L 10 14", c, 1.2)
    out["toolbar-handle"] = "".join(f'<rect x="7" y="{y}" width="2" height="2" style="fill:{EDGE}"/>' for y in (2, 6, 10, 14))
    out["toolbar-separator"] = f'<rect x="7.5" y="1" width="1" height="14" style="fill:{BEVEL}"/>'
    out["header-separator"] = f'<rect x="7.5" y="2" width="1" height="12" style="fill:{BEVEL}"/>'
    return out


def svg(a):
    parts, y = [], 0
    for el, states in frames(a).items():
        x = 0
        h = 0
        for st, kw in states.items():
            fr = Frame(prefix=f"{el}-{st}", bare_center=True, **kw)
            body, w, hh = fr.svg(x, y)
            parts.append(body)
            x += w
            h = max(h, hh)
        y += h + 8
    # indicators in a grid of 20px cells
    for i, (iid, body) in enumerate(indicators(a).items()):
        cx, cy = (i % 24) * 20, y + (i // 24) * 20
        parts.append(f'<g id="{iid}" transform="translate({cx} {cy})"><rect width="16" height="16" style="fill:#000;fill-opacity:0.004"/>{body}</g>')
    height = y + (len(indicators(a)) // 24 + 1) * 20
    return f'<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="600" height="{height}" viewBox="0 0 600 {height}">\n' + "\n".join(parts) + "\n</svg>\n"


def kvconfig(crystal, a):
    sel = mix(PANEL, a, 0.55)
    return f"""[%General]
author=KyberOS
comment=Imperial console widgets, {crystal} kyber crystal
x11drag=all
alt_mnemonic=true
left_tabs=false
attach_active_tab=true
group_toolbar_buttons=false
spread_progressbar=true
progressbar_thickness=6
composite=true
menu_shadow_depth=0
tooltip_shadow_depth=0
spread_menuitems=true
splitter_width=7
scroll_width=10
scroll_min_extent=48
scroll_arrows=false
combo_as_lineedit=true
inline_spin_indicators=true
slider_width=4
slider_handle_width=14
slider_handle_length=14
check_size=15
toolbar_icon_size=16
animate_states=true
transient_groove=false
transient_scrollbar=true
respect_DE=true
no_inactiveness=false

[GeneralColors]
window.color={PANEL}
base.color={DEEP}
alt.base.color={mix(DEEP, STEEL, 0.5)}
button.color={STEEL}
light.color={RAISED}
mid.light.color={STEEL}
dark.color={VOID}
mid.color={BEVEL}
highlight.color={sel}
inactive.highlight.color={mix(PANEL, a, 0.3)}
text.color={TEXT}
window.text.color={TEXT}
button.text.color={TEXT}
disabled.text.color={FAINT}
tooltip.text.color={DATA}
highlight.text.color={TEXT}
link.color={mix(a, TEXT, 0.15)}
link.visited.color={mix(a, '#b264ff', 0.5)}
progress.indicator.text.color={VOID}

[Hacks]
respect_darkness=true
transparent_ktitle_label=true
transparent_dolphin_view=false
kcapacitybar_as_progressbar=true

[PanelButtonCommand]
frame=true
frame.element=button
frame.top=4
frame.bottom=4
frame.left=4
frame.right=4
interior=true
interior.element=button
indicator.size=10
indicator.element=arrow
text.normal.color={TEXT}
text.focus.color={TEXT}
text.press.color={TEXT}
text.toggle.color={TEXT}
text.shadow=0
text.margin=1
text.iconspacing=4
text.margin.top=3
text.margin.bottom=3
text.margin.left=4
text.margin.right=4

[PanelButtonTool]
inherits=PanelButtonCommand
interior.element=tbutton
frame.element=tbutton

[Dock]
inherits=PanelButtonCommand

[DockTitle]
inherits=PanelButtonCommand
frame=false
interior=false
text.bold=true

[IndicatorSpinBox]
inherits=PanelButtonCommand
indicator.element=arrow
indicator.size=10

[RadioButton]
inherits=PanelButtonCommand
frame=false
interior.element=radio

[CheckBox]
inherits=PanelButtonCommand
frame=false
interior.element=checkbox

[GenericFrame]
inherits=PanelButtonCommand
frame=true
interior=false
frame.element=common
interior.element=common

[LineEdit]
inherits=PanelButtonCommand
frame.element=lineedit
interior.element=lineedit
text.margin.left=3
text.margin.right=3

[DropDownButton]
inherits=PanelButtonCommand
indicator.element=arrow-down

[IndicatorArrow]
indicator.element=arrow
indicator.size=10

[ToolboxTab]
inherits=PanelButtonCommand

[Tab]
inherits=PanelButtonCommand
interior.element=tab
frame.element=tab
indicator.element=tab
text.margin.left=8
text.margin.right=8
text.margin.top=4
text.margin.bottom=4
min_width=+4
min_height=2.1font

[TabFrame]
inherits=PanelButtonCommand
frame.element=tabframe
interior=false

[TreeExpander]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.size=10

[HeaderSection]
inherits=PanelButtonCommand
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2
text.margin.top=2
text.margin.bottom=2

[SizeGrip]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.element=resize-grip
indicator.size=13

[Toolbar]
inherits=PanelButtonCommand
indicator.element=toolbar
indicator.size=5
text.margin=0
frame.element=toolbar
interior=false

[Slider]
inherits=PanelButtonCommand
frame.element=slider
interior.element=slider
frame.top=3
frame.bottom=3
frame.left=3
frame.right=3

[SliderCursor]
inherits=PanelButtonCommand
frame=false
interior.element=slidercursor

[Progressbar]
inherits=PanelButtonCommand
frame.element=progress
interior.element=progress
frame.top=3
frame.bottom=3
frame.left=3
frame.right=3
text.margin=0
text.bold=true

[ProgressbarContents]
inherits=PanelButtonCommand
frame=true
frame.element=progress-pattern
interior.element=progress-pattern
frame.top=3
frame.bottom=3
frame.left=3
frame.right=3

[ItemView]
inherits=PanelButtonCommand
frame.element=itemview
interior.element=itemview
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2
text.margin=1
text.margin.top=2
text.margin.bottom=2
text.margin.left=3
text.margin.right=3

[Splitter]
inherits=PanelButtonCommand
interior.element=splitter
frame.element=splitter
frame.top=0
frame.bottom=0
frame.left=1
frame.right=1
indicator.element=splitter-grip
indicator.size=16

[Scrollbar]
inherits=PanelButtonCommand
indicator.size=10

[ScrollbarSlider]
inherits=PanelButtonCommand
frame.element=scrollbarslider
interior.element=scrollbarslider
frame.top=3
frame.bottom=3
frame.left=3
frame.right=3
indicator.element=grip
indicator.size=12

[ScrollbarTransientSlider]
frame=true
frame.element=ss
interior=false
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6

[ScrollbarGroove]
inherits=PanelButtonCommand
interior.element=scrollbargroove
frame.element=scrollbargroove
frame.top=0
frame.bottom=0
frame.left=3
frame.right=3

[MenuItem]
inherits=PanelButtonCommand
frame=true
frame.element=menuitem
interior.element=menuitem
indicator.element=menuitem
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2
text.margin.top=2
text.margin.bottom=2
text.margin.left=4
text.margin.right=4

[MenuBarItem]
inherits=PanelButtonCommand
interior.element=menubaritem
frame.element=menubaritem
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2
text.margin.left=6
text.margin.right=6

[TitleBar]
inherits=PanelButtonCommand
frame=false
interior=false
text.bold=true

[ComboBox]
inherits=PanelButtonCommand

[Menu]
inherits=PanelButtonCommand
frame.top=4
frame.bottom=4
frame.left=4
frame.right=4
frame.element=menu
interior.element=menu

[GroupBox]
inherits=GenericFrame
frame=true
frame.element=group
text.margin=0

[TabBarFrame]
inherits=GenericFrame
frame=false
interior=false

[ToolTip]
inherits=GenericFrame
frame.top=4
frame.bottom=4
frame.left=4
frame.right=4
interior=true
text.margin=0
interior.element=tooltip
frame.element=tooltip
text.normal.color={DATA}

[StatusBar]
inherits=GenericFrame
frame=false
interior=false

[Window]
interior=false
"""


def generate(out):
    for crystal, a in CRYSTALS.items():
        name = f"KyberOS-{crystal.capitalize()}"
        d = out / "Kvantum" / name
        d.mkdir(parents=True, exist_ok=True)
        (d / f"{name}.svg").write_text(svg(a))
        (d / f"{name}.kvconfig").write_text(kvconfig(crystal, a))
