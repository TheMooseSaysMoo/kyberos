/*
    KyberOS Tactical: animated Imperial tactical display wallpaper.
    Also used on the lock screen and the login greeter (with a banner line).
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Shapes
import org.kde.plasma.plasmoid

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

    // Geometry of the generated base art (gen_wallpaper.py), in source pixels.
    readonly property real srcW: 3840
    readonly property real srcH: 2160
    readonly property real fit: Math.max(width / srcW, height / srcH)
    readonly property real offX: (width - srcW * fit) / 2
    readonly property real offY: (height - srcH * fit) / 2
    function mapX(x) { return offX + x * fit }
    function mapY(y) { return offY + y * fit }

    Rectangle { anchors.fill: parent; color: "#06080b" }

    Image {
        id: base
        anchors.fill: parent
        source: Qt.resolvedUrl("../images/" + root.crystal + ".png")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }

    // ---- radar sweep -------------------------------------------------
    Item {
        id: radar
        readonly property real r: 300 * root.fit
        x: root.mapX(560) - r
        y: root.mapY(1660) - r
        width: r * 2
        height: r * 2

        Shape {
            id: sweep
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                fillGradient: ConicalGradient {
                    centerX: radar.r; centerY: radar.r
                    angle: 0
                    GradientStop { position: 0.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5) }
                    GradientStop { position: 0.16; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.0) }
                    GradientStop { position: 1.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.0) }
                }
                PathAngleArc { centerX: radar.r; centerY: radar.r; radiusX: radar.r; radiusY: radar.r; startAngle: 0; sweepAngle: 360 }
            }
            // leading edge
            Rectangle {
                x: radar.r; y: radar.r - 1
                width: radar.r; height: 2
                color: root.accent
                opacity: 0.9
            }
            RotationAnimator on rotation {
                from: 0; to: -360
                duration: Math.max(2, root.configuration.SweepSeconds) * 1000
                loops: Animation.Infinite
                running: root.animate
            }
        }
    }

    // ---- orbiting contact ---------------------------------------------
    Item {
        id: contact
        property real t: 0
        readonly property real cx: 2580; readonly property real cy: 960
        readonly property real rx: 945;  readonly property real ry: 227
        readonly property real tilt: -11 * Math.PI / 180
        readonly property real ex: rx * Math.cos(t)
        readonly property real ey: ry * Math.sin(t)
        x: root.mapX(cx + ex * Math.cos(tilt) - ey * Math.sin(tilt)) - width / 2
        y: root.mapY(cy + ex * Math.sin(tilt) + ey * Math.cos(tilt)) - height / 2
        width: 22 * root.fit * 1.6; height: width
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.5; height: width
            rotation: 45
            color: "transparent"
            border.color: root.accent
            border.width: Math.max(1, 3 * root.fit)
        }
        Rectangle { anchors.centerIn: parent; width: 4; height: 4; color: "#f4fbff" }
        NumberAnimation on t {
            from: 0; to: Math.PI * 2
            duration: 48000
            loops: Animation.Infinite
            running: root.animate
        }
    }

    // ---- status lights ------------------------------------------------
    Repeater {
        model: 14
        Rectangle {
            id: led
            x: root.mapX(200 + index * 26)
            y: root.mapY(226)
            width: 14 * root.fit
            height: 8 * root.fit
            readonly property var palette: [root.accent, root.accent, "#a6f2c4", "#ffb02e", "#ff3b2f", "#566476"]
            color: palette[(index * 7 + 3) % palette.length]
            opacity: 0.9
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.animate
                PauseAnimation { duration: 400 + (index * 733) % 2900 }
                NumberAnimation { to: 0.15; duration: 80 }
                PauseAnimation { duration: 120 + (index * 311) % 700 }
                NumberAnimation { to: 0.9; duration: 80 }
            }
        }
    }

    // ---- hologram scan band ---------------------------------------------
    Rectangle {
        id: scanBand
        width: parent.width
        height: parent.height * 0.12
        opacity: 0.07
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.85; color: root.accent }
            GradientStop { position: 1.0; color: "#ffffff" }
        }
        NumberAnimation on y {
            from: -scanBand.height; to: root.height
            duration: 9000
            loops: Animation.Infinite
            running: root.animate
        }
        visible: root.animate
    }

    // ---- banner (lock screen / login greeter) ---------------------------
    Item {
        visible: root.banner.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.12
        width: bannerText.implicitWidth + 80
        height: bannerText.implicitHeight + 28

        Shape {
            anchors.fill: parent
            ShapePath {
                strokeColor: "#ffb02e"
                strokeWidth: 2
                fillColor: Qt.rgba(0.024, 0.031, 0.043, 0.82)
                startX: 14; startY: 0
                PathLine { x: parent.width; y: 0 }
                PathLine { x: parent.width; y: parent.height - 14 }
                PathLine { x: parent.width - 14; y: parent.height }
                PathLine { x: 0; y: parent.height }
                PathLine { x: 0; y: 14 }
                PathLine { x: 14; y: 0 }
            }
        }
        Text {
            id: bannerText
            anchors.centerIn: parent
            text: root.banner
            color: "#ffb02e"
            font.family: "Orbitron"
            font.pixelSize: Math.max(16, root.height * 0.022)
            font.letterSpacing: font.pixelSize * 0.35
            font.weight: Font.DemiBold
        }
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: root.animate && root.banner.length > 0
            NumberAnimation { to: 0.55; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
        }
    }
}
