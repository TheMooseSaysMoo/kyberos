/*
    Targeting scene: a trench-run style targeting computer. A perspective
    tunnel rushes toward the viewer, the range counts down and the reticle
    closes until it locks, then the run repeats. Built for portrait screens,
    works in landscape too.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Shapes

Item {
    id: s
    property color accent: "#33b5ff"
    property bool animate: true
    readonly property color amber: "#ffb02e"
    readonly property color phosphor: "#a6f2c4"
    readonly property real u: Math.min(width, height)
    readonly property string mono: "Share Tech Mono"

    // vanishing point and trench mouth
    readonly property real vx: width / 2
    readonly property real vy: height * 0.34
    readonly property real farHalf: u * 0.035          // half width of the trench at the vanishing point
    readonly property real nearHalf: width * 0.62      // half width at the bottom edge
    readonly property real wallTop: u * 0.06           // trench wall height at the far end (screen px)

    function halfAt(y) { return farHalf + (nearHalf - farHalf) * (y - vy) / (height - vy) }

    // static trench walls
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.85)
            strokeWidth: Math.max(1.5, s.u * 0.002)
            fillColor: "transparent"
            PathMultiline {
                paths: [
                    // floor edges
                    [Qt.point(s.vx - s.farHalf, s.vy), Qt.point(s.vx - s.nearHalf, s.height)],
                    [Qt.point(s.vx + s.farHalf, s.vy), Qt.point(s.vx + s.nearHalf, s.height)],
                    // wall tops
                    [Qt.point(s.vx - s.farHalf, s.vy - s.wallTop), Qt.point(s.vx - s.nearHalf, s.vy - s.wallTop * 14)],
                    [Qt.point(s.vx + s.farHalf, s.vy - s.wallTop), Qt.point(s.vx + s.nearHalf, s.vy - s.wallTop * 14)],
                    // far wall
                    [Qt.point(s.vx - s.farHalf, s.vy), Qt.point(s.vx - s.farHalf, s.vy - s.wallTop),
                     Qt.point(s.vx + s.farHalf, s.vy - s.wallTop), Qt.point(s.vx + s.farHalf, s.vy)]
                ]
            }
        }
        // floor centre line
        ShapePath {
            strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.35); strokeWidth: 1; fillColor: "transparent"
            strokeStyle: ShapePath.DashLine; dashPattern: [6, 6]
            PathPolyline { path: [Qt.point(s.vx, s.vy), Qt.point(s.vx, s.height)] }
        }
    }

    // ribs rushing toward the viewer: depth d in (1..N], screen y ~ 1/d
    property real phase: 0
    NumberAnimation on phase { from: 0; to: 1; duration: 900; loops: Animation.Infinite; running: s.animate }
    Repeater {
        model: 16
        Item {
            id: rib
            readonly property real d: 16 - index - s.phase + 1     // 1..16
            readonly property real t: 1 / d                          // 0..1 (near = 1)
            readonly property real ry: s.vy + (s.height - s.vy) * t
            readonly property real half: s.halfAt(ry)
            readonly property real wall: s.wallTop + (s.wallTop * 13) * (ry - s.vy) / (s.height - s.vy)
            opacity: Math.min(1, t * 3)
            Shape {
                ShapePath {
                    strokeColor: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.7)
                    strokeWidth: Math.max(1, 2.5 * rib.t)
                    fillColor: "transparent"
                    PathPolyline {
                        path: [Qt.point(s.vx - rib.half, rib.ry - rib.wall), Qt.point(s.vx - rib.half, rib.ry),
                               Qt.point(s.vx + rib.half, rib.ry), Qt.point(s.vx + rib.half, rib.ry - rib.wall)]
                    }
                }
            }
        }
    }

    // ---- run cycle: range counts down, reticle closes, lock ------------------------
    property real run: 0          // 0..1 over one attack run
    NumberAnimation on run { from: 0; to: 1; duration: 14000; loops: Animation.Infinite; running: s.animate }
    readonly property bool locked: run > 0.82
    readonly property real range: Math.max(0, (1 - run / 0.82)) * 9.6

    Item {
        id: reticle
        x: s.vx; y: s.vy - s.wallTop * 0.5
        readonly property real gap: s.u * (0.04 + 0.22 * Math.max(0, 1 - s.run / 0.82))
        readonly property real arm: s.u * 0.06
        readonly property color c: s.locked ? s.amber : s.phosphor
        Repeater {
            model: [[-1, -1], [1, -1], [-1, 1], [1, 1]]
            Shape {
                ShapePath {
                    strokeColor: reticle.c; strokeWidth: Math.max(2, s.u * 0.003); fillColor: "transparent"
                    PathPolyline {
                        path: [Qt.point(modelData[0] * reticle.gap, modelData[1] * (reticle.gap - reticle.arm)),
                               Qt.point(modelData[0] * reticle.gap, modelData[1] * reticle.gap),
                               Qt.point(modelData[0] * (reticle.gap - reticle.arm), modelData[1] * reticle.gap)]
                    }
                }
            }
        }
        Rectangle { x: -3; y: -3; width: 6; height: 6; color: reticle.c }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: s.height * 0.06
        spacing: s.u * 0.012
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "TARGETING COMPUTER"
            color: s.accent; font.family: s.mono; font.pixelSize: Math.max(14, s.u * 0.032); font.letterSpacing: 6
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "RANGE  " + s.range.toFixed(2).padStart(5, "0") + "  KM"
            color: s.locked ? s.amber : s.phosphor
            font.family: s.mono; font.pixelSize: Math.max(16, s.u * 0.045); font.letterSpacing: 4
        }
        Text {
            id: lockText
            anchors.horizontalCenter: parent.horizontalCenter
            text: s.locked ? "TARGET LOCKED" : "ACQUIRING"
            color: s.locked ? s.amber : Qt.rgba(s.phosphor.r, s.phosphor.g, s.phosphor.b, 0.6)
            font.family: s.mono; font.pixelSize: Math.max(12, s.u * 0.024); font.letterSpacing: 6
            SequentialAnimation {
                loops: Animation.Infinite; running: s.animate
                OpacityAnimator { target: lockText; to: 0.3; duration: 260 }
                OpacityAnimator { target: lockText; to: 1.0; duration: 260 }
            }
        }
    }

    // side rulers
    Repeater {
        model: 2
        Column {
            id: rulerCol
            readonly property bool onLeft: index === 0
            width: s.u * 0.04
            x: onLeft ? s.width * 0.05 : s.width * 0.95 - width
            y: s.height * 0.42
            spacing: s.u * 0.018
            Repeater {
                model: 18
                Rectangle {
                    width: (index % 5 === 0 ? 1 : 0.5) * rulerCol.width
                    x: rulerCol.onLeft ? 0 : rulerCol.width - width
                    height: 2
                    color: s.accent
                    opacity: 0.55
                }
            }
        }
    }
}
