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
import QtQuick.Shapes
import QtQuick.Window
import org.kde.plasma.plasmoid
import "scenes"

WallpaperItem {
    id: root

    readonly property var crystals: ({
        blue: "#33b5ff", green: "#3ef08a", red: "#ff2d3f",
        purple: "#b264ff", yellow: "#ffd23c", white: "#e2f4ff"
    })
    readonly property string crystal: crystals[root.configuration.Crystal] ? root.configuration.Crystal : "blue"
    readonly property color accent: crystals[crystal]
    readonly property bool animate: root.configuration.Animate
    readonly property string banner: root.configuration.Banner || ""
    readonly property real u: Math.min(width, height)

    readonly property string scene: {
        const pinned = root.configuration.Scene || "auto"
        if (pinned !== "auto") return pinned
        if (height > width * 1.1) {
            // portrait: left half of the desktop gets targeting, right half comms
            const mid = Screen.virtualX + Screen.width / 2
            return mid < Screen.desktopAvailableWidth / 2 ? "targeting" : "comms"
        }
        return "tactical"
    }

    // ---- background ---------------------------------------------------------
    Rectangle { anchors.fill: parent; color: "#06080b" }
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.width * 0.62; centerY: root.height * 0.42
                centerRadius: Math.max(root.width, root.height) * 0.75
                focalX: centerX; focalY: centerY
                GradientStop { position: 0.0; color: "#121b25" }
                GradientStop { position: 0.55; color: "#0a0e13" }
                GradientStop { position: 1.0; color: "#06080b" }
            }
            PathRectangle { x: 0; y: 0; width: root.width; height: root.height }
        }
    }
    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../images/hex.svg")
        fillMode: Image.Tile
        sourceSize: Qt.size(Math.round(root.u * 0.045), Math.round(root.u * 0.045 * 3 / Math.sqrt(3)))
        opacity: 0.45
        smooth: true
    }

    // ---- scene ----------------------------------------------------------------
    Loader {
        id: sceneLoader
        anchors.fill: parent
        sourceComponent: ({ tactical: tactical, schematic: schematic, targeting: targeting, comms: comms })[root.scene] || tactical
    }
    Component { id: tactical; Tactical { accent: root.accent; animate: root.animate; sweepSeconds: root.configuration.SweepSeconds } }
    Component { id: schematic; Schematic { accent: root.accent; animate: root.animate } }
    Component { id: targeting; Targeting { accent: root.accent; animate: root.animate } }
    Component { id: comms; Comms { accent: root.accent; animate: root.animate } }

    // ---- hologram scan band (render-thread animated) ----------------------------
    Rectangle {
        id: scanBand
        width: parent.width
        height: parent.height * 0.12
        opacity: 0.06
        visible: root.animate
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0) }
            GradientStop { position: 0.9; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.6) }
            GradientStop { position: 0.97; color: root.accent }
            GradientStop { position: 1.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0) }
        }
        YAnimator on y { from: -scanBand.height; to: root.height; duration: 9000; loops: Animation.Infinite; running: root.animate }
    }

    // ---- overlays: scanlines, vignette, frame marks, wordmark ----------------
    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../images/scan.svg")
        fillMode: Image.Tile
        sourceSize: Qt.size(4, 4)
    }
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.width / 2; centerY: root.height / 2
                centerRadius: Math.max(root.width, root.height) * 0.72
                focalX: centerX; focalY: centerY
                GradientStop { position: 0.6; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
            }
            PathRectangle { x: 0; y: 0; width: root.width; height: root.height }
        }
    }
    Shape {
        id: frameMarks
        anchors.fill: parent
        readonly property real m: root.u * 0.028
        readonly property real l: root.u * 0.055
        ShapePath {
            strokeColor: "#566476"; strokeWidth: 2; fillColor: "transparent"
            PathMultiline {
                paths: {
                    const m = frameMarks.m, l = frameMarks.l, w = root.width, h = root.height
                    return [[Qt.point(m, m + l), Qt.point(m, m), Qt.point(m + l, m)],
                            [Qt.point(w - m - l, m), Qt.point(w - m, m), Qt.point(w - m, m + l)],
                            [Qt.point(m, h - m - l), Qt.point(m, h - m), Qt.point(m + l, h - m)],
                            [Qt.point(w - m - l, h - m), Qt.point(w - m, h - m), Qt.point(w - m, h - m - l)]]
                }
            }
        }
    }
    Image {
        visible: root.scene === "tactical" || root.scene === "schematic"
        source: Qt.resolvedUrl("../images/wordmark-" + root.crystal + ".svg")
        sourceSize.width: Math.round(root.u * 0.36)
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.rightMargin: root.u * 0.07; anchors.bottomMargin: root.u * 0.08
        opacity: 0.75
    }

    // ---- banner (lock screen / login greeter) ---------------------------------------
    Item {
        id: bannerBox
        visible: root.banner.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.8
        width: bannerText.implicitWidth + 80
        height: bannerText.implicitHeight + 28
        readonly property real cut: 14

        Shape {
            anchors.fill: parent
            ShapePath {
                strokeColor: "#ffb02e"
                strokeWidth: 2
                fillColor: Qt.rgba(0.024, 0.031, 0.043, 0.82)
                startX: bannerBox.cut; startY: 0
                PathLine { x: bannerBox.width; y: 0 }
                PathLine { x: bannerBox.width; y: bannerBox.height - bannerBox.cut }
                PathLine { x: bannerBox.width - bannerBox.cut; y: bannerBox.height }
                PathLine { x: 0; y: bannerBox.height }
                PathLine { x: 0; y: bannerBox.cut }
                PathLine { x: bannerBox.cut; y: 0 }
            }
        }
        Text {
            id: bannerText
            anchors.centerIn: parent
            text: root.banner
            color: "#ffb02e"
            font.family: "Orbitron"
            readonly property real size: Math.max(14, root.height * 0.018)
            font.pixelSize: size
            font.letterSpacing: size * 0.35
            font.weight: Font.DemiBold
        }
        SequentialAnimation {
            loops: Animation.Infinite
            running: root.animate && root.banner.length > 0
            OpacityAnimator { target: bannerBox; to: 0.55; duration: 900; easing.type: Easing.InOutSine }
            OpacityAnimator { target: bannerBox; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
        }
    }
}
