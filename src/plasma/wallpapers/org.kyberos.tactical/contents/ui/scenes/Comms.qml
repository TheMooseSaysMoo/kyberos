/*
    Comms scene: rotating comm array, live oscilloscope trace and scrolling
    data columns. Built for portrait screens; reflows side by side in landscape.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Shapes
import "geo.js" as Geo

Item {
    id: s
    property color accent: "#33b5ff"
    property bool animate: true
    readonly property color amber: "#ffb02e"
    readonly property color phosphor: "#a6f2c4"
    readonly property real u: Math.min(width, height)
    readonly property bool portrait: height >= width
    readonly property string mono: "Share Tech Mono"

    // ---- comm array (stacked rotating rings) ------------------------------------
    Item {
        id: array
        readonly property real r: s.u * (s.portrait ? 0.34 : 0.3)
        x: (s.portrait ? s.width * 0.5 : s.width * 0.27) - r
        y: (s.portrait ? s.height * 0.25 : s.height * 0.5) - r
        width: r * 2; height: r * 2

        Repeater {
            model: [
                { f: 1.0, n: 24, gap: 0.35, w: 2, o: 0.5, dur: 60000, dir: 1 },
                { f: 0.86, n: 6, gap: 0.12, w: 5, o: 0.85, dur: 24000, dir: -1 },
                { f: 0.7, n: 36, gap: 0.5, w: 2, o: 0.4, dur: 40000, dir: 1 },
                { f: 0.56, n: 3, gap: 0.2, w: 3, o: 0.75, dur: 12000, dir: 1 },
                { f: 0.4, n: 12, gap: 0.3, w: 2, o: 0.5, dur: 18000, dir: -1 },
            ]
            Shape {
                id: ring
                anchors.fill: parent
                // smoother curve renderer where available (Qt 6.6+); older Qt keeps the default
                Component.onCompleted: if (typeof preferredRendererType !== "undefined") preferredRendererType = 4
                ShapePath {
                    strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, modelData.o)
                    strokeWidth: modelData.w; fillColor: "transparent"; capStyle: ShapePath.FlatCap
                    PathMultiline { paths: Geo.segments(array.r, array.r, array.r * modelData.f, modelData.n, modelData.gap, 0) }
                }
                RotationAnimator on rotation {
                    from: 0; to: 360 * modelData.dir; duration: modelData.dur
                    loops: Animation.Infinite; running: s.animate
                }
            }
        }
        // core
        Rectangle {
            id: core
            anchors.centerIn: parent
            width: array.r * 0.22; height: width; radius: width / 2
            color: "transparent"; border.color: s.accent; border.width: 2
            Rectangle { anchors.centerIn: parent; width: parent.width * 0.45; height: width; radius: width / 2; color: s.accent }
            SequentialAnimation {
                loops: Animation.Infinite; running: s.animate
                ScaleAnimator { target: core; to: 1.12; duration: 700; easing.type: Easing.OutQuad }
                ScaleAnimator { target: core; to: 1.0; duration: 1100; easing.type: Easing.InOutQuad }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom; anchors.topMargin: s.u * 0.03
            text: "SUBSPACE RELAY  //  CH 07"
            color: s.accent; font.family: s.mono; font.pixelSize: Math.max(13, s.u * 0.026); font.letterSpacing: 5
        }
    }

    // ---- oscilloscope -------------------------------------------------------------
    Item {
        id: scope
        x: s.portrait ? s.width * 0.08 : s.width * 0.52
        y: s.portrait ? s.height * 0.5 : s.height * 0.12
        width: s.portrait ? s.width * 0.84 : s.width * 0.42
        height: s.u * 0.18
        property real t: 0
        NumberAnimation on t { from: 0; to: Math.PI * 2; duration: 4000; loops: Animation.Infinite; running: s.animate }

        Rectangle { anchors.fill: parent; color: Qt.rgba(0.024, 0.031, 0.043, 0.55); border.color: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.45); border.width: 1 }
        Shape {
            anchors.fill: parent
            ShapePath {   // graticule
                strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.15); strokeWidth: 1; fillColor: "transparent"
                PathMultiline {
                    paths: {
                        var out = []
                        for (var i = 1; i < 10; ++i) out.push([Qt.point(scope.width * i / 10, 0), Qt.point(scope.width * i / 10, scope.height)])
                        for (var j = 1; j < 4; ++j) out.push([Qt.point(0, scope.height * j / 4), Qt.point(scope.width, scope.height * j / 4)])
                        return out
                    }
                }
            }
            ShapePath {   // trace
                strokeColor: s.phosphor; strokeWidth: 2; fillColor: "transparent"
                PathPolyline {
                    path: {
                        var pts = [], n = 140
                        for (var i = 0; i <= n; ++i) {
                            var x = i / n
                            var a = x * Math.PI * 2
                            var v = 0.55 * Math.sin(a * 3 + scope.t) + 0.25 * Math.sin(a * 11 - scope.t * 3)
                                    + 0.12 * Math.sin(a * 29 + scope.t * 5)
                            v *= 0.5 + 0.5 * Math.sin(a + scope.t)    // envelope
                            pts.push(Qt.point(x * scope.width, scope.height * (0.5 - v * 0.42)))
                        }
                        return pts
                    }
                }
            }
        }
        Text {
            anchors.left: parent.left; anchors.bottom: parent.top; anchors.bottomMargin: 4
            text: "CARRIER 14.207 GHZ   SNR 31 DB"
            color: s.phosphor; opacity: 0.75; font.family: s.mono; font.pixelSize: Math.max(10, s.u * 0.016); font.letterSpacing: 3
        }
    }

    // ---- scrolling data columns ---------------------------------------------------
    Item {
        id: columns
        x: scope.x
        y: scope.y + scope.height + s.u * 0.05
        width: scope.width
        height: s.height * 0.94 - y
        clip: true
        readonly property int count: s.u > 0 ? Math.min(60, Math.max(4, Math.floor(width / (s.u * 0.075)))) : 4
        Row {
            spacing: columns.width / columns.count * 0.25
            Repeater {
                model: columns.count
                Item {
                    id: col
                    width: columns.width / columns.count * 0.75
                    height: columns.height
                    readonly property string glyphs: {
                        var set = "ABCDEFGHJKLMNPRSTVXYZ0123456789/=+<>[]#"
                        var r = Geo.rng(101 + index * 37), lines = []
                        for (var i = 0; i < 40; ++i) {
                            var w = ""
                            for (var k = 0; k < 4; ++k) w += set.charAt(Math.floor(r() * set.length))
                            lines.push(w)
                        }
                        return lines.join("\n")
                    }
                    Column {
                        id: stream
                        // two copies stacked: scrolling one copy's height loops seamlessly
                        Repeater {
                            model: 2
                            Text {
                                text: col.glyphs
                                color: index % 2 ? s.phosphor : s.accent
                                opacity: 0.7
                                font.family: s.mono
                                font.pixelSize: Math.max(10, s.u * 0.02)
                                lineHeight: 1.25
                                transform: Scale { xScale: -1; origin.x: col.width / 2 }   // mirrored = alien script
                            }
                        }
                        YAnimator on y {
                            from: 0; to: -stream.height / 2
                            duration: 16000 + (index * 3700) % 12000
                            loops: Animation.Infinite; running: s.animate
                        }
                    }
                }
            }
        }
        // fade top and bottom edges
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#06080b" }
                GradientStop { position: 0.12; color: "transparent" }
                GradientStop { position: 0.88; color: "transparent" }
                GradientStop { position: 1.0; color: "#06080b" }
            }
        }
    }
}
