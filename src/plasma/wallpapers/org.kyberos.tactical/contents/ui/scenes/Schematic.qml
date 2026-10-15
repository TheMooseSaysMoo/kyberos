/*
    Schematic scene: an (original) Imperial-style capital ship blueprint with
    deck lines, labelled callouts, dimension rulers and a scanning beam.
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
    readonly property bool portrait: height > width
    readonly property string mono: "Share Tech Mono"

    // ship drawing box (nose points right in landscape, up in portrait)
    Item {
        id: ship
        readonly property real len: s.portrait ? Math.min(s.height * 0.62, s.width * 2.2) : Math.min(s.width * 0.62, s.height * 1.55)
        readonly property real wid: len * 0.4
        width: len; height: wid
        anchors.centerIn: parent
        anchors.verticalCenterOffset: s.portrait ? 0 : -s.height * 0.03
        rotation: s.portrait ? -90 : 0

        function pts(list) { return Geo.scale(list, ship.len, ship.wid, 0, 0) }

        // hull outline, normalised (x along length, y across width)
        readonly property var hull: [[1.0, 0.5], [0.24, 0.04], [0.16, 0.06], [0.16, 0.0], [0.08, 0.0], [0.08, 0.1], [0.03, 0.18],
                                     [0.0, 0.3], [0.0, 0.7], [0.03, 0.82], [0.08, 0.9], [0.08, 1.0], [0.16, 1.0], [0.16, 0.94],
                                     [0.24, 0.96], [1.0, 0.5]]
        readonly property var deck: [[0.86, 0.5], [0.27, 0.16], [0.2, 0.2], [0.2, 0.8], [0.27, 0.84], [0.86, 0.5]]

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {   // hull
                strokeColor: s.accent; strokeWidth: Math.max(1.5, s.u * 0.002)
                fillColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.06)
                PathPolyline { path: ship.pts(ship.hull) }
            }
            ShapePath {   // inner deck + spine + frame ribs
                strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.4); strokeWidth: 1; fillColor: "transparent"
                PathMultiline {
                    paths: {
                        var out = [ship.pts(ship.deck), ship.pts([[0.0, 0.5], [0.96, 0.5]])]
                        for (var i = 1; i < 9; ++i) {
                            var x = 0.24 + i * 0.075
                            var half = 0.46 * (1 - (x - 0.24) / 0.76)
                            out.push(ship.pts([[x, 0.5 - half], [x, 0.5 + half]]))
                        }
                        return out
                    }
                }
            }
            ShapePath {   // engines, bridge, hangar
                strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.8); strokeWidth: 1.2; fillColor: "transparent"
                PathMultiline {
                    paths: [Geo.ellipse(ship.len * 0.035, ship.wid * 0.36, ship.wid * 0.06, ship.wid * 0.06, 0, 32),
                            Geo.ellipse(ship.len * 0.035, ship.wid * 0.5, ship.wid * 0.075, ship.wid * 0.075, 0, 32),
                            Geo.ellipse(ship.len * 0.035, ship.wid * 0.64, ship.wid * 0.06, ship.wid * 0.06, 0, 32),
                            ship.pts([[0.1, 0.4], [0.2, 0.4], [0.2, 0.6], [0.1, 0.6], [0.1, 0.4]]),
                            ship.pts([[0.42, 0.44], [0.58, 0.44], [0.58, 0.56], [0.42, 0.56], [0.42, 0.44]])]
                }
            }
        }
        // reactor core pulses
        Rectangle {
            id: reactor
            x: ship.len * 0.3 - width / 2; y: ship.wid * 0.5 - height / 2
            width: ship.wid * 0.16; height: width; radius: width / 2
            color: "transparent"; border.color: s.amber; border.width: 2
            Rectangle { anchors.centerIn: parent; width: parent.width * 0.4; height: width; radius: width / 2; color: s.amber; opacity: 0.8 }
            SequentialAnimation {
                loops: Animation.Infinite; running: s.animate
                OpacityAnimator { target: reactor; to: 0.45; duration: 900; easing.type: Easing.InOutSine }
                OpacityAnimator { target: reactor; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
            }
        }
        // scanning beam across the hull
        Rectangle {
            id: beam
            width: Math.max(2, ship.len * 0.004); height: ship.wid * 1.1
            y: -ship.wid * 0.05
            color: s.accent
            opacity: 0.75
            Rectangle {
                anchors.right: parent.left
                width: ship.len * 0.08; height: parent.height
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.3) }
                }
            }
            XAnimator on x { from: 0; to: ship.len; duration: 7000; loops: Animation.Infinite; running: s.animate }
        }
    }

    // ---- callouts (in screen space, so labels stay upright) ------------------
    // ship-local normalised point -> scene point (same maths as the ship's own layout)
    function shipPoint(nx, ny) {
        var lx = (nx - 0.5) * ship.len, ly = (ny - 0.5) * ship.wid
        var a = ship.rotation * Math.PI / 180
        var cx = s.width / 2, cy = s.height / 2 + (s.portrait ? 0 : -s.height * 0.03)
        return Qt.point(cx + lx * Math.cos(a) - ly * Math.sin(a), cy + lx * Math.sin(a) + ly * Math.cos(a))
    }
    Repeater {
        model: [
            { label: "BRIDGE TOWER", nx: 0.15, ny: 0.4, dx: -0.12, dy: -0.16 },
            { label: "MAIN REACTOR", nx: 0.3, ny: 0.5, dx: -0.06, dy: 0.2 },
            { label: "HANGAR 02", nx: 0.5, ny: 0.56, dx: 0.06, dy: 0.18 },
            { label: "SHIELD GENERATOR", nx: 0.62, ny: 0.32, dx: 0.1, dy: -0.15 },
            { label: "ION DRIVE ARRAY", nx: 0.035, ny: 0.64, dx: -0.14, dy: 0.12 },
        ]
        Item {
            id: callout
            readonly property point at: s.shipPoint(modelData.nx, modelData.ny)
            readonly property point tip: Qt.point(at.x + modelData.dx * s.u, at.y + modelData.dy * s.u)
            Shape {
                ShapePath {
                    strokeColor: Qt.rgba(s.phosphor.r, s.phosphor.g, s.phosphor.b, 0.7); strokeWidth: 1; fillColor: "transparent"
                    PathPolyline { path: [callout.at, callout.tip, Qt.point(callout.tip.x + (modelData.dx < 0 ? -1 : 1) * s.u * 0.05, callout.tip.y)] }
                }
            }
            Rectangle { x: callout.at.x - 3; y: callout.at.y - 3; width: 6; height: 6; color: s.phosphor }
            Text {
                text: modelData.label
                color: s.phosphor
                font.family: s.mono
                font.pixelSize: Math.max(11, s.u * 0.016)
                font.letterSpacing: 2
                x: modelData.dx < 0 ? callout.tip.x - s.u * 0.05 - implicitWidth : callout.tip.x + s.u * 0.006
                y: callout.tip.y - implicitHeight - 2
            }
            SequentialAnimation {
                loops: Animation.Infinite; running: s.animate
                PauseAnimation { duration: 1400 * index }
                OpacityAnimator { target: callout; to: 0.35; duration: 120 }
                OpacityAnimator { target: callout; to: 1.0; duration: 300 }
                PauseAnimation { duration: 7000 - 1400 * index }
            }
        }
    }

    // ---- dimension ruler + title block ------------------------------------------
    Shape {
        id: ruler
        anchors.fill: parent
        readonly property point a: s.shipPoint(0, 1.18)
        readonly property point b: s.shipPoint(1, 1.18)
        ShapePath {
            strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.6); strokeWidth: 1; fillColor: "transparent"
            PathMultiline {
                paths: {
                    var out = [[ruler.a, ruler.b]]
                    for (var i = 0; i <= 20; ++i) {
                        var t = i / 20
                        var x = ruler.a.x + (ruler.b.x - ruler.a.x) * t
                        var y = ruler.a.y + (ruler.b.y - ruler.a.y) * t
                        var l = (i % 5 === 0 ? 0.012 : 0.006) * s.u
                        out.push(s.portrait ? [Qt.point(x, y), Qt.point(x + l, y)] : [Qt.point(x, y), Qt.point(x, y + l)])
                    }
                    return out
                }
            }
        }
    }
    Text {
        text: "LENGTH 1,137 M"
        color: s.accent; opacity: 0.8
        font.family: s.mono; font.pixelSize: Math.max(11, s.u * 0.015); font.letterSpacing: 3
        x: (ruler.a.x + ruler.b.x) / 2 - implicitWidth / 2 + (s.portrait ? s.u * 0.03 : 0)
        y: (ruler.a.y + ruler.b.y) / 2 + s.u * 0.018
        rotation: s.portrait ? -90 : 0
    }
    Column {
        x: s.width * 0.05; y: s.height * 0.08
        spacing: s.u * 0.006
        Text { text: "SCHEMATIC  //  CLASS II CRUISER"; color: s.accent; font.family: s.mono; font.pixelSize: Math.max(13, s.u * 0.02); font.letterSpacing: 4 }
        Text { text: "DECK PLAN 07-G   REV 4"; color: s.phosphor; opacity: 0.7; font.family: s.mono; font.pixelSize: Math.max(10, s.u * 0.013); font.letterSpacing: 3 }
        Readout { colour: s.phosphor; rows: 4; rowHeight: s.u * 0.008; barWidth: s.u * 0.2; seed: 11; animate: s.animate }
    }
    Readout {
        anchors.right: parent.right; anchors.rightMargin: s.width * 0.05
        anchors.bottom: parent.bottom; anchors.bottomMargin: s.height * 0.12
        colour: s.accent; rows: 4; rowHeight: s.u * 0.008; barWidth: s.u * 0.22; seed: 13; animate: s.animate
    }
}
