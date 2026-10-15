/*
    KyberOS wipe: a hard vertical edge sweeps across the screen, the old
    desktop's windows vanish behind it and the new desktop's appear.
    Each window animates its own edge position (in its texture space), so
    the edge lines up across every window on the screen.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
"use strict";

class KyberWipeEffect {
    constructor() {
        const traits = Effect.MapTexture | Effect.Modulate;
        this.inShader = effect.addFragmentShader(traits, "wipe.frag");
        this.outShader = effect.addFragmentShader(traits, "wipe.frag");
        effect.setUniform(this.inShader, "uMode", 0.0);
        effect.setUniform(this.outShader, "uMode", 1.0);
        effect.configChanged.connect(this.loadConfig.bind(this));
        effects.desktopChanged.connect(this.desktopChanged.bind(this));
        this.loadConfig();
    }

    loadConfig() {
        this.duration = animationTime(effect.readConfig("Duration", 520));
        const accent = effect.readConfig("Accent", "#33b5ff");
        effect.setUniform(this.inShader, "uAccent", accent);
        effect.setUniform(this.outShader, "uAccent", accent);
    }

    static desktopIndex(desktop) {
        const all = effects.desktops;
        for (let i = 0; i < all.length; ++i) {
            if (all[i] === desktop) {
                return i;
            }
        }
        return 0;
    }

    desktopChanged(oldDesktop, newDesktop, movingWindow, screen) {
        if (effects.hasActiveFullScreenEffect && !effect.isActiveFullScreenEffect) {
            return;
        }
        // moving 'forward' wipes left-to-right, backward right-to-left
        const forward = KyberWipeEffect.desktopIndex(newDesktop) >= KyberWipeEffect.desktopIndex(oldDesktop);
        const dir = forward ? 1.0 : -1.0;
        effect.setUniform(this.inShader, "uDir", dir);
        effect.setUniform(this.outShader, "uDir", dir);

        const stack = effects.stackingOrder;
        for (let i = 0; i < stack.length; ++i) {
            const w = stack[i];
            if (w === movingWindow || w.screen !== screen || w.minimized) {
                continue;
            }
            if (!w.isOnActivity(effects.currentActivity)) {
                continue;
            }
            const onOld = w.isOnDesktop(oldDesktop);
            const onNew = w.isOnDesktop(newDesktop);
            if (onOld === onNew) {
                continue;
            }
            this.wipe(w, onNew, forward, screen);
        }
    }

    wipe(w, incoming, forward, screen) {
        if (w.kyberWipe) {
            cancel(w.kyberWipe);
            delete w.kyberWipe;
        }
        // edge travels across the screen; express it in this window's texture u
        const geo = w.expandedGeometry;
        const area = screen ? screen.geometry : { x: 0, y: 0, width: effects.virtualScreenSize.width, height: effects.virtualScreenSize.height };
        const toU = x => (x - geo.x) / Math.max(1, geo.width);
        const start = forward ? area.x : area.x + area.width;
        const end = forward ? area.x + area.width : area.x;
        w.kyberWipe = animate({
            window: w,
            duration: this.duration,
            curve: QEasingCurve.InOutCubic,
            fullScreen: true,
            keepAlive: false,
            animations: [{
                type: Effect.ShaderUniform,
                fragmentShader: incoming ? this.inShader : this.outShader,
                uniform: "uEdge",
                from: toU(start),
                to: toU(end),
            }],
        });
    }
}

new KyberWipeEffect();
