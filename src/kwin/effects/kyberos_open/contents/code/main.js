/*
    KyberOS window open/close.
      open, normal windows:   projected as a hologram out of their dock icon
      open, dialogs/notices:  hologram materialises in place
      close, everything:      power-down to a line, then a point
    SPDX-License-Identifier: GPL-3.0-or-later
*/
"use strict";

const blacklist = {
    "ksmserver ksmserver": [],
    "ksmserver-logout-greeter ksmserver-logout-greeter": [],
    "ksplashqml ksplashqml": [],
    "spectacle org.kde.spectacle": ["region-editor"],
};

class KyberOpenEffect {
    constructor() {
        const traits = Effect.MapTexture | Effect.Modulate;
        this.projShader = effect.addFragmentShader(traits, "projector.frag");
        this.holoShader = effect.addFragmentShader(traits, "hologram.frag");
        this.offShader = effect.addFragmentShader(traits, "powerdown.frag");
        effect.configChanged.connect(this.loadConfig.bind(this));
        effect.animationEnded.connect(this.cleanup.bind(this));
        effects.windowAdded.connect(this.windowAdded.bind(this));
        effects.windowClosed.connect(this.windowClosed.bind(this));
        this.loadConfig();
    }

    loadConfig() {
        this.projectDuration = animationTime(effect.readConfig("ProjectDuration", 480));
        this.holoDuration = animationTime(effect.readConfig("HologramDuration", 380));
        this.offDuration = animationTime(effect.readConfig("PowerDownDuration", 320));
        const accent = effect.readConfig("Accent", "#33b5ff");
        for (const s of [this.projShader, this.holoShader, this.offShader]) {
            effect.setUniform(s, "uAccent", accent);
        }
    }

    // "project" (normal windows), "holo" (dialogs, notifications) or "" to leave alone
    static kind(window) {
        const tags = blacklist[window.windowClass];
        if (tags && (tags.length === 0 || tags.includes(window.tag))) {
            return "";
        }
        if (window.lockScreen || window.outline || window.desktopWindow || window.dock) {
            return "";
        }
        if (window.notification || window.criticalNotification || window.onScreenDisplay) {
            return "holo";
        }
        if (window.windowClass === "plasmashell plasmashell" || window.windowClass === "plasmashell org.kde.plasmashell") {
            return window.hasDecoration ? "holo" : "";
        }
        if (window.popupWindow || window.popupMenu || window.dropdownMenu || window.tooltip || window.comboBox || window.dndIcon) {
            return "";
        }
        if (!window.managed) {
            return "";
        }
        if (window.dialog || window.utility || window.splash) {
            return "holo";
        }
        return window.normalWindow ? "project" : "";
    }

    // Where the projection starts: the window's dock icon, or the dock's spot
    // (bottom centre of its screen) while the task button isn't laid out yet.
    static projectorRect(window) {
        const icon = window.iconGeometry;
        if (icon && icon.width > 0 && icon.height > 0) {
            return icon;
        }
        const s = window.screen ? window.screen.geometry
            : { x: 0, y: 0, width: effects.virtualScreenSize.width, height: effects.virtualScreenSize.height };
        return { x: s.x + s.width / 2 - 24, y: s.y + s.height - 72, width: 48, height: 48 };
    }

    forceRoles(window, on) {
        window.setData(Effect.WindowForceBackgroundContrastRole, on ? true : null);
        window.setData(Effect.WindowForceBlurRole, on ? true : null);
    }

    cleanup(window) {
        this.forceRoles(window, false);
        delete window.kyberOpen;
    }

    shaderOnly(window, shader, duration) {
        return animate({
            window: window,
            duration: duration,
            curve: QEasingCurve.Linear,
            animations: [{ type: Effect.ShaderUniform, fragmentShader: shader, uniform: "uProgress", from: 0.0, to: 1.0 }],
        });
    }

    project(window) {
        const g = window.geometry;
        const src = KyberOpenEffect.projectorRect(window);
        // start as a small beam-shaped sliver above the icon
        const w0 = Math.max(8, src.width * 0.6);
        const h0 = Math.max(8, src.height * 0.9);
        return animate({
            window: window,
            duration: this.projectDuration,
            curve: QEasingCurve.OutCubic,
            animations: [
                {
                    type: Effect.Size,
                    from: { value1: w0, value2: h0 },
                    to: { value1: g.width, value2: g.height },
                },
                {
                    type: Effect.Translation,
                    from: {
                        value1: src.x + src.width / 2 - (g.x + g.width / 2),
                        value2: src.y + src.height / 2 - (g.y + g.height / 2),
                    },
                    to: { value1: 0.0, value2: 0.0 },
                },
                { type: Effect.ShaderUniform, fragmentShader: this.projShader, uniform: "uProgress", from: 0.0, to: 1.0, curve: QEasingCurve.Linear },
            ],
        });
    }

    windowAdded(window) {
        if (effects.hasActiveFullScreenEffect || !window.visible) {
            return;
        }
        if (effect.isGrabbed(window, Effect.WindowAddedGrabRole)) {
            return;
        }
        const kind = KyberOpenEffect.kind(window);
        if (!kind) {
            return;
        }
        this.forceRoles(window, true);
        window.kyberOpen = kind === "project" ? this.project(window)
            : this.shaderOnly(window, this.holoShader, this.holoDuration);
    }

    windowClosed(window) {
        if (effects.hasActiveFullScreenEffect || !window.visible || window.skipsCloseAnimation) {
            return;
        }
        if (effect.isGrabbed(window, Effect.WindowClosedGrabRole)) {
            return;
        }
        if (!KyberOpenEffect.kind(window)) {
            return;
        }
        if (window.kyberOpen) {
            cancel(window.kyberOpen);
            delete window.kyberOpen;
        }
        window.setData(Effect.WindowClosedGrabRole, effect);
        this.forceRoles(window, true);
        this.shaderOnly(window, this.offShader, this.offDuration);
    }
}

new KyberOpenEffect();
