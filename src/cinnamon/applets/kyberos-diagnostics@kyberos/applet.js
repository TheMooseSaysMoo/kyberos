/*
    KyberOS Ship Diagnostics for the Cinnamon panel: CPU / RAM / DISK as lit segment bars
    (red when nearly full). Click for the full readout: CPU temperature, per-core load,
    GPU (when the driver exposes it), network and disk I/O. Reads /proc and /sys directly.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
const Applet = imports.ui.applet;
const PopupMenu = imports.ui.popupMenu;
const { St, Gio, GLib, Clutter } = imports.gi;
const ByteArray = imports.byteArray;

const CRYSTALS = {
    blue: "#33b5ff", green: "#3ef08a", red: "#ff2d3f",
    purple: "#b264ff", yellow: "#ffd23c", white: "#e2f4ff",
};
const ALERT = [1, 0.231, 0.184], OFF = [0.212, 0.255, 0.31];
const SEGMENTS = 10;

function read(path) {
    try {
        const [ok, bytes] = GLib.file_get_contents(path);
        return ok ? ByteArray.toString(bytes) : "";
    } catch (e) {
        return "";
    }
}

function hexRgb(hex) {
    return [1, 3, 5].map(i => parseInt(hex.substr(i, 2), 16) / 255);
}

function accent() {
    const name = read(GLib.get_user_data_dir() + "/kyberos/crystal").trim();
    return hexRgb(CRYSTALS[name] || CRYSTALS.blue);
}

function rate(bytesPerSec) {
    const u = ["B", "K", "M", "G"];
    let i = 0, v = bytesPerSec;
    while (v >= 1000 && i < u.length - 1) { v /= 1024; i++; }
    return (v < 10 && i ? v.toFixed(1) : Math.round(v)) + u[i];
}

class KyberDiagnostics extends Applet.Applet {
    constructor(metadata, orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);
        this.setAllowedLayout(Applet.AllowedLayout.BOTH);
        this.set_applet_tooltip("Ship diagnostics");

        this._box = new St.BoxLayout({ style: "spacing: 12px; padding: 0 4px;" });
        this.actor.add_child(this._box);
        this._bars = {};
        for (const label of ["CPU", "RAM", "DISK"]) this._bars[label] = this._readout(label);

        this._menuManager = new PopupMenu.PopupMenuManager(this);
        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this._menuManager.addMenu(this.menu);
        const head = new PopupMenu.PopupMenuItem("SHIP DIAGNOSTICS", { reactive: false });
        head.label.style = "font-family: Michroma; letter-spacing: 3px; font-size: 9pt; min-width: 300px;";
        this.menu.addMenuItem(head);
        this._rows = {};
        for (const k of ["CPU", "CPU TEMP", "CPU CORES", "GPU", "RAM", "DISK", "NETWORK", "DISK I/O"]) {
            const item = new PopupMenu.PopupMenuItem(k, { reactive: false });
            // fixed width: the menu sizes itself before the readings arrive and would ellipsize them
            item.label.style = "font-family: 'Share Tech Mono'; color: #a6f2c4; min-width: 300px;";
            item.label.clutter_text.ellipsize = 0;
            this.menu.addMenuItem(item);
            this._rows[k] = item;
        }

        this._prev = {};
        this._update();
        this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 2, () => { this._update(); return GLib.SOURCE_CONTINUE; });
    }

    _readout(label) {
        const col = new St.BoxLayout({ vertical: true, y_align: Clutter.ActorAlign.CENTER, style: "spacing: 2px;" });
        col.add_child(new St.Label({ text: label, style: "font-family: Michroma; font-size: 6.5pt; color: #8793a3; letter-spacing: 1px;" }));
        const area = new St.DrawingArea({ width: 46, height: 5 });
        const bar = { value: 0, area };
        area.connect("repaint", a => this._paint(a, bar.value));
        col.add_child(area);
        this._box.add_child(col);
        return bar;
    }

    _paint(area, v) {
        const cr = area.get_context();
        const [w, h] = area.get_surface_size();
        const gap = 1, sw = (w - gap * (SEGMENTS - 1)) / SEGMENTS;
        const lit = Math.round(Math.max(0, Math.min(1, v)) * SEGMENTS);
        const a = accent();
        for (let i = 0; i < SEGMENTS; i++) {
            const on = i < lit;
            const c = on ? (v > 0.9 && i >= SEGMENTS - 2 ? ALERT : a) : OFF;
            cr.setSourceRGBA(c[0], c[1], c[2], on ? 1 : 0.7);
            cr.rectangle(i * (sw + gap), 0, sw, h);
            cr.fill();
        }
        cr.$dispose();
    }

    _cpu() {
        const lines = read("/proc/stat").split("\n").filter(l => l.startsWith("cpu"));
        const out = [];
        for (const l of lines) {
            const f = l.trim().split(/\s+/);
            const nums = f.slice(1).map(Number);
            const idle = nums[3] + (nums[4] || 0);
            const total = nums.reduce((s, x) => s + x, 0);
            const p = this._prev[f[0]];
            this._prev[f[0]] = [idle, total];
            out.push(p && total > p[1] ? 1 - (idle - p[0]) / (total - p[1]) : 0);
        }
        return out;   // [all, core0, core1, ...]
    }

    _mem() {
        const m = {};
        for (const l of read("/proc/meminfo").split("\n")) {
            const [k, v] = l.split(":");
            if (v) m[k] = parseInt(v);
        }
        return m.MemTotal ? { used: (m.MemTotal - m.MemAvailable) / m.MemTotal, total: m.MemTotal * 1024, usedB: (m.MemTotal - m.MemAvailable) * 1024 } : { used: 0 };
    }

    _disk() {
        try {
            const info = Gio.File.new_for_path("/").query_filesystem_info("filesystem::size,filesystem::free", null);
            const size = info.get_attribute_uint64("filesystem::size"), free = info.get_attribute_uint64("filesystem::free");
            return size ? { used: (size - free) / size, size, free } : { used: 0 };
        } catch (e) {
            return { used: 0 };
        }
    }

    _temp() {
        let best = null;
        const dir = Gio.File.new_for_path("/sys/class/hwmon");
        try {
            const en = dir.enumerate_children("standard::name", 0, null);
            let fi;
            while ((fi = en.next_file(null))) {
                const base = "/sys/class/hwmon/" + fi.get_name();
                const name = read(base + "/name").trim();
                if (!/k10temp|coretemp|zenpower|cpu_thermal|acpitz/.test(name)) continue;
                const t = parseInt(read(base + "/temp1_input"));
                if (t && (best === null || t > best)) best = t;
            }
        } catch (e) { /* no hwmon */ }
        return best === null ? null : best / 1000;
    }

    _gpu() {
        for (let i = 0; i < 4; i++) {
            const v = read(`/sys/class/drm/card${i}/device/gpu_busy_percent`).trim();
            if (v !== "") return parseInt(v) / 100;
        }
        return null;
    }

    _rates() {
        const now = GLib.get_monotonic_time() / 1e6;
        let rx = 0, tx = 0, rd = 0, wr = 0;
        for (const l of read("/proc/net/dev").split("\n").slice(2)) {
            const [iface, rest] = l.split(":");
            if (!rest || iface.trim() === "lo") continue;
            const f = rest.trim().split(/\s+/).map(Number);
            rx += f[0]; tx += f[8];
        }
        for (const l of read("/proc/diskstats").split("\n")) {
            const f = l.trim().split(/\s+/);
            if (f.length < 10 || !/^(sd[a-z]+|vd[a-z]+|nvme\d+n\d+|mmcblk\d+)$/.test(f[2])) continue;
            rd += Number(f[5]) * 512; wr += Number(f[9]) * 512;
        }
        const p = this._prev.io, out = { rx: 0, tx: 0, rd: 0, wr: 0 };
        if (p) {
            const dt = Math.max(0.5, now - p.t);
            out.rx = (rx - p.rx) / dt; out.tx = (tx - p.tx) / dt; out.rd = (rd - p.rd) / dt; out.wr = (wr - p.wr) / dt;
        }
        this._prev.io = { t: now, rx, tx, rd, wr };
        return out;
    }

    _update() {
        const cpu = this._cpu(), mem = this._mem(), disk = this._disk();
        const pct = v => String(Math.round(v * 100)).padStart(3) + "%";
        this._bars.CPU.value = cpu[0] || 0;
        this._bars.RAM.value = mem.used;
        this._bars.DISK.value = disk.used;
        for (const b of Object.values(this._bars)) b.area.queue_repaint();
        this.set_applet_tooltip(`CPU ${pct(cpu[0] || 0)}   RAM ${pct(mem.used)}   DISK ${pct(disk.used)}`);

        const io = this._rates();
        if (!this.menu.isOpen) return;
        const t = this._temp(), g = this._gpu();
        const gb = b => (b / 1073741824).toFixed(1) + " G";
        const set = (k, v) => this._rows[k].label.set_text(k.padEnd(10) + v);
        set("CPU", pct(cpu[0] || 0));
        set("CPU TEMP", t === null ? "--" : t.toFixed(0) + " °C");
        set("CPU CORES", cpu.slice(1).map(c => "▁▂▃▄▅▆▇█"[Math.min(7, Math.floor(c * 8))]).join(""));
        this._rows["GPU"].actor.visible = g !== null;
        if (g !== null) set("GPU", pct(g));
        set("RAM", `${pct(mem.used)}  ${mem.usedB ? gb(mem.usedB) + " / " + gb(mem.total) : ""}`);
        set("DISK", `${pct(disk.used)}  ${disk.size ? gb(disk.size - disk.free) + " / " + gb(disk.size) : ""}`);
        set("NETWORK", `▼ ${rate(io.rx)}/s  ▲ ${rate(io.tx)}/s`);
        set("DISK I/O", `R ${rate(io.rd)}/s  W ${rate(io.wr)}/s`);
    }

    on_applet_clicked() {
        this._update();
        this.menu.toggle();
        if (this.menu.isOpen) this._update();
    }

    on_applet_removed_from_panel() {
        if (this._timer) GLib.source_remove(this._timer);
        this._timer = 0;
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new KyberDiagnostics(metadata, orientation, panelHeight, instanceId);
}
