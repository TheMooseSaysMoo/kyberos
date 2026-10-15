/*
    KyberOS Holoprojector for Cinnamon.
      open, normal windows:  projected out of their panel icon as a hologram
      open, dialogs:         hologram materialises in place
      close, both:           power-down to a line, then a point
    The GLSL is generated at build time from the KWin effect's shaders (build/gen_cinnamon.py).

    How it hooks in: Cinnamon's WindowManager binds its 'map'/'destroy' handlers once, so
    replacing methods later does nothing. We swap those two signal handlers for ours, which
    still call Cinnamon's own _mapWindow/_destroyWindow (sounds, dimming, bookkeeping) with
    the stock effect set to "none" and a proxy window manager whose completed_map /
    completed_destroy only reach Muffin when our animation ends. Disabling restores the
    original handlers.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
const { GObject, GLib, Clutter, Meta, Cinnamon } = imports.gi;
const Main = imports.ui.main;
const ByteArray = imports.byteArray;

const CRYSTALS = {
    blue: "#33b5ff", green: "#3ef08a", red: "#ff2d3f",
    purple: "#b264ff", yellow: "#ffd23c", white: "#e2f4ff",
};
const DURATION = { project: 480, holo: 380, off: 320 };

let meta = null;
let classes = null;
let hooks = null;          // { origMapId, origDestroyId, mapId, destroyId, killId }
const running = new Map(); // actor -> finish()

function shaderSource(name) {
    const [ok, bytes] = GLib.file_get_contents(`${meta.path}/shaders/${name}.glsl`);
    const text = ByteArray.toString(bytes);
    const [decl, code] = text.split("//@@CODE@@");
    return { decl, code };
}

let loadId = 0;

function makeClass(name) {
    const src = shaderSource(name);
    // GLSLEffect caches one pipeline per class, so each shader gets its own class. Anonymous
    // classes would all get the same auto GType name, and a re-enable registers them again,
    // hence the explicit, per-load unique names.
    return GObject.registerClass({ GTypeName: `KyberOSFx_${name}_${loadId}_${Date.now()}` }, class extends Cinnamon.GLSLEffect {
        vfunc_build_pipeline() {
            this.add_glsl_snippet(Cinnamon.SnippetHook.FRAGMENT, src.decl, src.code, false);
        }
    });
}

function accent() {
    let name = "blue";
    try {
        const [ok, bytes] = GLib.file_get_contents(GLib.get_user_data_dir() + "/kyberos/crystal");
        name = ByteArray.toString(bytes).trim();
    } catch (e) { /* default */ }
    const hex = CRYSTALS[name] || CRYSTALS.blue;
    return [1, 3, 5].map(i => parseInt(hex.substr(i, 2), 16) / 255).concat([1]);
}

function forced() {
    return GLib.file_test(GLib.get_user_config_dir() + "/kyberos/force-animations", GLib.FileTest.EXISTS);
}

function shouldAnimate(actor) {
    if (Main.modalCount) return false;
    if (!Main.animations_enabled && !forced()) return false;   // software rendering
    const t = actor.meta_window.get_window_type();
    if (t === Meta.WindowType.NORMAL) return Main.wm.desktop_effects_windows !== false;
    return Main.wm.desktop_effects_dialogs !== false;
}

function kind(actor) {
    const w = actor.meta_window;
    if (!w || w.is_override_redirect()) return "";
    switch (w.get_window_type()) {
        case Meta.WindowType.NORMAL: return "project";
        case Meta.WindowType.DIALOG:
        case Meta.WindowType.MODAL_DIALOG: return "holo";
        default: return "";
    }
}

const ease = p => 1 - Math.pow(1 - p, 3);

// run one shader animation on an actor; onFrame(p) for extra transforms; done() at the end
function animate(actor, Klass, ms, uniforms, onFrame, done) {
    finishRunning(actor);
    const fx = new Klass();
    const loc = n => fx.get_uniform_location(n);
    const lp = loc("uProgress");
    fx.set_uniform_float(loc("uAccent"), 4, accent());
    fx.set_uniform_float(loc("uSize"), 2, [Math.max(1, actor.width), Math.max(1, actor.height)]);
    for (const [k, v] of Object.entries(uniforms)) fx.set_uniform_float(loc(k), 1, [v]);
    fx.set_uniform_float(lp, 1, [0]);
    actor.add_effect_with_name("kyberos-fx", fx);

    const tl = new Clutter.Timeline({ duration: ms });
    let finished = false;
    const finish = () => {
        if (finished) return;
        finished = true;
        tl.stop();
        running.delete(actor);
        if (onFrame) onFrame(1);
        try { actor.remove_effect_by_name("kyberos-fx"); } catch (e) { /* actor gone */ }
        done();
    };
    tl.connect("new-frame", () => {
        const p = tl.get_progress();
        fx.set_uniform_float(lp, 1, [p]);
        fx.queue_repaint();
        if (onFrame) onFrame(p);
    });
    tl.connect("completed", finish);
    running.set(actor, finish);
    tl.start();
}

function finishRunning(actor) {
    const f = running.get(actor);
    if (f) f();
}

function project(actor, done) {
    // fly out of the panel icon (set by the window list), or from the bottom centre
    const w = actor.meta_window;
    let src = null;
    try {
        const [ok, rect] = w.get_icon_geometry();
        if (ok && rect.width > 0) src = rect;
    } catch (e) { /* older muffin */ }
    if (!src) {
        const mon = Main.layoutManager.monitors[w.get_monitor()] || Main.layoutManager.primaryMonitor;
        src = { x: mon.x + mon.width / 2 - 24, y: mon.y + mon.height - 48, width: 48, height: 48 };
    }
    const [x, y] = actor.get_position();
    const [aw, ah] = actor.get_size();
    const sx = Math.max(0.05, src.width / aw), sy = Math.max(0.05, src.height / ah);
    actor.set_pivot_point(0, 0);
    const frame = p => {
        const e = ease(p);
        actor.scale_x = sx + (1 - sx) * e;
        actor.scale_y = sy + (1 - sy) * e;
        actor.translation_x = (src.x - x) * (1 - e);
        actor.translation_y = (src.y - y) * (1 - e);
    };
    frame(0);
    animate(actor, classes.projector, DURATION.project, {}, frame, () => {
        actor.scale_x = actor.scale_y = 1;
        actor.translation_x = actor.translation_y = 0;
        done();
    });
}

function onMap(cwm, actor) {
    const k = kind(actor);
    if (!k || !shouldAnimate(actor)) return Main.wm._mapWindow(cwm, actor);
    const proxy = {
        completed_map: a => (k === "project"
            ? project(a, () => cwm.completed_map(a))
            : animate(a, classes.hologram, DURATION.holo, { uClosing: 0 }, null, () => cwm.completed_map(a))),
    };
    const saved = Main.wm.desktop_effects_map_type;
    Main.wm.desktop_effects_map_type = "none";
    try {
        Main.wm._mapWindow(proxy, actor);
    } finally {
        Main.wm.desktop_effects_map_type = saved;
    }
}

function onDestroy(cwm, actor) {
    const k = kind(actor);
    if (!k || actor.meta_window.minimized || !shouldAnimate(actor)) return Main.wm._destroyWindow(cwm, actor);
    finishRunning(actor);
    const proxy = {
        completed_destroy: a => animate(a, classes.powerdown, DURATION.off, {}, null, () => cwm.completed_destroy(a)),
    };
    const saved = Main.wm.desktop_effects_close_type;
    Main.wm.desktop_effects_close_type = "none";
    try {
        Main.wm._destroyWindow(proxy, actor);
    } finally {
        Main.wm.desktop_effects_close_type = saved;
    }
}

function init(metadata) {
    meta = metadata;
}

function enable() {
    if (!classes) {
        loadId++;
        classes = { projector: makeClass("projector"), hologram: makeClass("hologram"), powerdown: makeClass("powerdown") };
    }
    const wm = global.window_manager;
    const origMapId = GObject.signal_handler_find(wm, { signalId: "map" });
    const origDestroyId = GObject.signal_handler_find(wm, { signalId: "destroy" });
    if (!origMapId || !origDestroyId) {
        global.logError("kyberos-effects: Cinnamon's window handlers not found, not enabling");
        return;
    }
    wm.disconnect(origMapId);
    wm.disconnect(origDestroyId);
    hooks = {
        mapId: wm.connect("map", onMap),
        destroyId: wm.connect("destroy", onDestroy),
        killId: wm.connect("kill-window-effects", (c, actor) => finishRunning(actor)),
    };
}

function disable() {
    if (!hooks) return;
    const wm = global.window_manager;
    for (const actor of Array.from(running.keys())) finishRunning(actor);
    wm.disconnect(hooks.mapId);
    wm.disconnect(hooks.destroyId);
    wm.disconnect(hooks.killId);
    wm.connect("map", Main.wm._mapWindow.bind(Main.wm));
    wm.connect("destroy", Main.wm._destroyWindow.bind(Main.wm));
    hooks = null;
}
