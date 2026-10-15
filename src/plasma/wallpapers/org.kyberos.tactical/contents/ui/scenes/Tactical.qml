/*
    Tactical scene: rotating wireframe planet with an orbit and tracked
    contact, target lock with readout, radar scope, status lights.
    Laid out from the screen's own size, so it works at any aspect ratio.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Shapes
import "geo.js" as Geo

Item {
    id: s
    property color accent: "#33b5ff"
    property bool animate: true
    property int sweepSeconds: 6
    readonly property color amber: "#ffb02e"
    readonly property color phosphor: "#a6f2c4"
    readonly property real u: Math.min(width, height)
    readonly property bool portrait: height > width

    // ---- planet ---------------------------------------------------------
    Item {
        id: planet
        readonly property real r: s.u * (s.portrait ? 0.34 : 0.26)
        readonly property real tilt: -18 * Math.PI / 180
        x: s.width * (s.portrait ? 0.5 : (s.width / s.height > 2 ? 0.6 : 0.65)) - r
        y: s.height * (s.portrait ? 0.38 : 0.46) - r
        width: r * 2
        height: r * 2

        property real phase: 0
        NumberAnimation on phase {
            from: 0; to: Math.PI / 6       // meridians repeat every 30 degrees
            duration: 9000
            loops: Animation.Infinite
            running: s.animate
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            // body + rim
            ShapePath {
                strokeColor: s.accent
                strokeWidth: Math.max(1.5, s.u * 0.0018)
                fillGradient: RadialGradient {
                    centerX: planet.r * 0.75; centerY: planet.r * 0.7; centerRadius: planet.r * 1.3
                    focalX: centerX; focalY: centerY
                    GradientStop { position: 0; color: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.18) }
                    GradientStop { position: 1; color: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.02) }
                }
                PathAngleArc { centerX: planet.r; centerY: planet.r; radiusX: planet.r; radiusY: planet.r; startAngle: 0; sweepAngle: 360 }
            }
            // latitude rings (static)
            ShapePath {
                strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.28)
                strokeWidth: 1
                fillColor: "transparent"
                PathMultiline {
                    paths: {
                        var out = []
                        for (var lat = -75; lat <= 75; lat += 15) {
                            var a = lat * Math.PI / 180
                            var rx = planet.r * Math.cos(a)
                            var cy = planet.r + planet.r * Math.sin(a)
                            out.push(Geo.ellipse(planet.r, cy, rx, rx * 0.16, 0, 72))
                        }
                        return out
                    }
                }
            }
            // meridians, turning with phase
            ShapePath {
                strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.22)
                strokeWidth: 1
                fillColor: "transparent"
                PathMultiline {
                    paths: {
                        var out = []
                        for (var i = 0; i < 6; ++i) {
                            var a = planet.phase + i * Math.PI / 6
                            out.push(Geo.ellipse(planet.r, planet.r, Math.abs(planet.r * Math.sin(a)), planet.r, 0, 72))
                        }
                        return out
                    }
                }
            }
        }
        rotation: -18
    }

    // ---- orbit + tracked contact --------------------------------------------
    Shape {
        id: orbit
        anchors.fill: parent
        readonly property real cx: planet.x + planet.r
        readonly property real cy: planet.y + planet.r
        readonly property real rx: planet.r * (s.portrait ? 1.35 : 1.75)
        readonly property real ry: planet.r * 0.42
        readonly property real tilt: -11 * Math.PI / 180
        ShapePath {
            strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.5)
            strokeWidth: 1.5
            fillColor: "transparent"
            strokeStyle: ShapePath.DashLine
            dashPattern: [8, 6]
            PathPolyline { path: Geo.ellipse(orbit.cx, orbit.cy, orbit.rx, orbit.ry, orbit.tilt, 120) }
        }
    }
    Item {
        id: contact
        property real t: 0
        readonly property real ex: orbit.rx * Math.cos(t)
        readonly property real ey: orbit.ry * Math.sin(t)
        x: orbit.cx + ex * Math.cos(orbit.tilt) - ey * Math.sin(orbit.tilt) - width / 2
        y: orbit.cy + ex * Math.sin(orbit.tilt) + ey * Math.cos(orbit.tilt) - height / 2
        width: s.u * 0.022; height: width
        // only bright on the near side of the planet
        opacity: Math.sin(t) > -0.2 ? 1 : 0.35
        Rectangle { anchors.centerIn: parent; width: parent.width * 0.6; height: width; rotation: 45; color: "transparent"; border.color: s.accent; border.width: 2 }
        Rectangle { anchors.centerIn: parent; width: 4; height: 4; color: "#f4fbff" }
        NumberAnimation on t { from: 0; to: Math.PI * 2; duration: 48000; loops: Animation.Infinite; running: s.animate }
    }

    // ---- target lock + readout ----------------------------------------------
    Item {
        id: lock
        readonly property real size: s.u * 0.03
        x: planet.x + planet.r * 1.28 - size / 2
        y: planet.y + planet.r * 0.62 - size / 2
        width: size; height: size
        Rectangle { anchors.fill: parent; color: "transparent"; border.color: s.amber; border.width: 2 }
        SequentialAnimation on scale {
            loops: Animation.Infinite; running: s.animate
            NumberAnimation { from: 1.6; to: 1.0; duration: 700; easing.type: Easing.OutCubic }
            PauseAnimation { duration: 3300 }
        }
    }
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor: s.amber; strokeWidth: 1.5; fillColor: "transparent"
            PathPolyline {
                path: [Qt.point(lock.x + lock.width, lock.y),
                       Qt.point(lock.x + lock.width + s.u * 0.12, lock.y - s.u * 0.1),
                       Qt.point(lock.x + lock.width + s.u * 0.26, lock.y - s.u * 0.1)]
            }
        }
    }
    Readout {
        x: lock.x + lock.width + s.u * 0.135
        y: lock.y - s.u * 0.1 - height - s.u * 0.012
        colour: s.amber; rows: 6; rowHeight: s.u * 0.009; barWidth: s.u * 0.13; seed: 7; animate: s.animate
    }

    // ---- radar ------------------------------------------------------------
    Item {
        id: radar
        readonly property real r: s.u * (s.portrait ? 0.2 : 0.14)
        x: (s.portrait ? s.width * 0.5 : s.width * 0.14) - r
        y: (s.portrait ? s.height * 0.8 : s.height * 0.76) - r
        width: r * 2; height: r * 2
        readonly property int period: Math.max(2, s.sweepSeconds) * 1000

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.75)
                strokeWidth: 2
                fillColor: Qt.rgba(0.024, 0.031, 0.043, 0.55)
                PathAngleArc { centerX: radar.r; centerY: radar.r; radiusX: radar.r; radiusY: radar.r; startAngle: 0; sweepAngle: 360 }
            }
            ShapePath {
                strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.28)
                strokeWidth: 1; fillColor: "transparent"
                PathMultiline {
                    paths: [Geo.ellipse(radar.r, radar.r, radar.r * 0.25, radar.r * 0.25, 0, 48),
                            Geo.ellipse(radar.r, radar.r, radar.r * 0.5, radar.r * 0.5, 0, 64),
                            Geo.ellipse(radar.r, radar.r, radar.r * 0.75, radar.r * 0.75, 0, 80),
                            [Qt.point(0, radar.r), Qt.point(radar.r * 2, radar.r)],
                            [Qt.point(radar.r, 0), Qt.point(radar.r, radar.r * 2)]]
                }
            }
            ShapePath {
                strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.6)
                strokeWidth: 1.5; fillColor: "transparent"
                PathMultiline { paths: Geo.ticks(radar.r, radar.r, radar.r, 72, 6, radar.r * 0.03, radar.r * 0.07) }
            }
        }
        // sweep (render-thread rotation)
        Shape {
            id: sweep
            anchors.fill: parent
            ShapePath {
                strokeWidth: -1
                fillGradient: ConicalGradient {
                    centerX: radar.r; centerY: radar.r; angle: 0
                    GradientStop { position: 0.0; color: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.5) }
                    GradientStop { position: 0.16; color: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.0) }
                    GradientStop { position: 1.0; color: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.0) }
                }
                PathAngleArc { centerX: radar.r; centerY: radar.r; radiusX: radar.r; radiusY: radar.r; startAngle: 0; sweepAngle: 360 }
            }
            Rectangle { x: radar.r; y: radar.r - 1; width: radar.r; height: 2; color: s.accent }
            RotationAnimator on rotation { from: 0; to: -360; duration: radar.period; loops: Animation.Infinite; running: s.animate }
        }
        // blips flare as the sweep passes them
        Repeater {
            model: 6
            Rectangle {
                id: blip
                readonly property var r0: Geo.rng(31 + index * 7)
                readonly property real ang: r0() * 360
                readonly property real dist: (0.2 + r0() * 0.7) * radar.r
                x: radar.r + dist * Math.cos(ang * Math.PI / 180) - width / 2
                y: radar.r + dist * Math.sin(ang * Math.PI / 180) - height / 2
                width: Math.max(4, radar.r * 0.035); height: width
                color: s.accent
                opacity: 0.2
                readonly property int hit: Math.round(((360 - ang) % 360) / 360 * radar.period)
                // wait for the first pass, then flare once per revolution
                SequentialAnimation {
                    running: s.animate
                    PauseAnimation { duration: blip.hit }
                    SequentialAnimation {
                        loops: Animation.Infinite
                        OpacityAnimator { target: blip; to: 1.0; duration: 60 }
                        OpacityAnimator { target: blip; to: 0.2; duration: radar.period * 0.6 }
                        PauseAnimation { duration: radar.period * 0.4 - 60 }
                    }
                }
            }
        }
    }

    // ---- status lights + data blocks ------------------------------------------
    Row {
        x: s.width * 0.05; y: s.height * 0.09
        spacing: s.u * 0.008
        Repeater {
            model: 14
            Rectangle {
                id: led
                readonly property var palette: [s.accent, s.accent, s.phosphor, s.amber, "#ff3b2f", "#566476"]
                width: s.u * 0.012; height: s.u * 0.006
                color: palette[(index * 7 + 3) % palette.length]
                SequentialAnimation {
                    loops: Animation.Infinite; running: s.animate
                    PauseAnimation { duration: 400 + (index * 733) % 2900 }
                    OpacityAnimator { target: led; to: 0.15; duration: 80 }
                    PauseAnimation { duration: 120 + (index * 311) % 700 }
                    OpacityAnimator { target: led; to: 1.0; duration: 80 }
                }
            }
        }
    }
    Readout {
        x: s.width * 0.05; y: s.height * 0.09 + s.u * 0.022
        colour: s.phosphor; rows: 5; rowHeight: s.u * 0.009; barWidth: s.u * 0.2; seed: 2; animate: s.animate
    }
    Readout {
        anchors.right: parent.right; anchors.rightMargin: s.width * 0.06
        y: s.height * (s.portrait ? 0.6 : 0.78)
        colour: s.accent; rows: 3; rowHeight: s.u * 0.008; barWidth: s.u * 0.26; seed: 5; animate: s.animate
    }
}
