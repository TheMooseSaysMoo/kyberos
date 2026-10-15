/*
    KyberOS window open/close: blast doors for normal windows,
    hologram materialise for dialogs and notifications.
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
        this.doorShader = effect.addFragmentShader(traits, "blastdoor.frag");
        this.holoShader = effect.addFragmentShader(traits, "hologram.frag");
        effect.configChanged.connect(this.loadConfig.bind(this));
        effect.animationEnded.connect(this.cleanup.bind(this));
        effects.windowAdded.connect(this.windowAdded.bind(this));
        effects.windowClosed.connect(this.windowClosed.bind(this));
        this.loadConfig();
    }

    loadConfig() {
        this.doorOpen = animationTime(effect.readConfig("DoorOpenDuration", 460));
        this.doorClose = animationTime(effect.readConfig("DoorCloseDuration", 320));
        this.holo = animationTime(effect.readConfig("HologramDuration", 380));
        const accent = effect.readConfig("Accent", "#33b5ff");
        effect.setUniform(this.doorShader, "uAccent", accent);
        effect.setUniform(this.holoShader, "uAccent", accent);
    }

    // "door", "holo" or "" for windows we leave alone
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
        if (!window.managed && !window.notification) {
            return "";
        }
        if (window.dialog || window.utility || window.splash || window.transient) {
            return "holo";
        }
        if (window.normalWindow) {
            return "door";
        }
        return "";
    }

    forceRoles(window, on) {
        window.setData(Effect.WindowForceBackgroundContrastRole, on ? true : null);
        window.setData(Effect.WindowForceBlurRole, on ? true : null);
    }

    cleanup(window) {
        this.forceRoles(window, false);
        delete window.kyberOpen;
    }

    animateWith(window, shader, duration, closing) {
        this.forceRoles(window, true);
        return animate({
            window: window,
            duration: duration,
            curve: QEasingCurve.Linear,
            animations: [
                { type: Effect.ShaderUniform, fragmentShader: shader, uniform: "uProgress", from: 0.0, to: 1.0 },
                { type: Effect.ShaderUniform, fragmentShader: shader, uniform: "uClosing", from: closing, to: closing },
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
        if (kind === "door") {
            window.kyberOpen = this.animateWith(window, this.doorShader, this.doorOpen, 0.0);
        } else if (kind === "holo") {
            window.kyberOpen = this.animateWith(window, this.holoShader, this.holo, 0.0);
        }
    }

    windowClosed(window) {
        if (effects.hasActiveFullScreenEffect || !window.visible || window.skipsCloseAnimation) {
            return;
        }
        if (effect.isGrabbed(window, Effect.WindowClosedGrabRole)) {
            return;
        }
        const kind = KyberOpenEffect.kind(window);
        if (!kind) {
            return;
        }
        if (window.kyberOpen) {
            cancel(window.kyberOpen);
            delete window.kyberOpen;
        }
        window.setData(Effect.WindowClosedGrabRole, effect);
        if (kind === "door") {
            this.animateWith(window, this.doorShader, this.doorClose, 1.0);
        } else {
            this.animateWith(window, this.holoShader, Math.round(this.holo * 0.7), 1.0);
        }
    }
}

new KyberOpenEffect();
