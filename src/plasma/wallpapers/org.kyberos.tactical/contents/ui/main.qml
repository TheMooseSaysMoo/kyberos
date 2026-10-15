/*
    KyberOS animated wallpaper. Each monitor picks a scene:
      Tactical   - wireframe planet, orbit, radar (landscape default)
      Schematic  - capital ship blueprint
      Targeting  - trench-run targeting computer (portrait, left of centre)
      Comms      - comm array, oscilloscope, data columns (portrait, right of centre)
    "auto" chooses from the monitor's orientation and position; any monitor can
    be pinned to a scene in its wallpaper settings. Also used on the lock screen
    and the login greeter (with a banner line).
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Window
import org.kde.plasma.plasmoid

WallpaperItem {
    id: root

    Backdrop {
        anchors.fill: parent
        crystal: root.configuration.Crystal || "blue"
        animate: root.configuration.Animate
        banner: root.configuration.Banner || ""
        sweepSeconds: root.configuration.SweepSeconds || 6
        scene: {
            const pinned = root.configuration.Scene || "auto"
            if (pinned !== "auto") return pinned
            if (height > width * 1.1) {
                // portrait: left half of the desktop gets targeting, right half comms
                const mid = Screen.virtualX + Screen.width / 2
                return mid < Screen.desktopAvailableWidth / 2 ? "targeting" : "comms"
            }
            return "tactical"
        }
    }
}
