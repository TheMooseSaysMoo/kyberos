/*
    KyberOS login splash: the stars stretch into hyperspace as Plasma loads,
    then the jump completes with a flash at the last stage.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick

Rectangle {
    id: root
    color: "#06080b"

    property int stage
    // 0..1 warp factor driven by ksplash's startup stages
    property real warp: 0.15
    Behavior on warp { NumberAnimation { duration: 900; easing.type: Easing.InQuad } }

    onStageChanged: {
        warp = Math.min(1, 0.15 + stage * 0.17);
        if (stage >= 5) {
            flash.start();
        }
    }

    Item {
        id: field
        anchors.fill: parent
        readonly property real maxD: Math.sqrt(width * width + height * height) / 2 + 60

        // Every star streaks outward on the render thread (Animators), so the
        // jump stays smooth while Plasma is busy starting up behind it.
        Repeater {
            model: 140
            Item {
                id: star
                readonly property real angle: (index * 137.508) % 360
                readonly property int dur: 1300 + (index * 211) % 2200
                x: field.width / 2
                y: field.height / 2
                rotation: angle

                Rectangle {
                    id: streak
                    width: Math.max(24, field.maxD * 0.09)
                    height: 2
                    radius: 1
                    transformOrigin: Item.Right
                    scale: 0.05
                    opacity: 0
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.7; color: "#9fd8ff" }
                        GradientStop { position: 1.0; color: "#ffffff" }
                    }
                    ParallelAnimation {
                        running: true
                        loops: Animation.Infinite
                        XAnimator { target: streak; from: 6 - streak.width; to: field.maxD; duration: star.dur; easing.type: Easing.InQuad }
                        ScaleAnimator { target: streak; from: 0.05; to: 1.8; duration: star.dur; easing.type: Easing.InQuad }
                        SequentialAnimation {
                            OpacityAnimator { target: streak; from: 0; to: 1; duration: star.dur * 0.25 }
                            PauseAnimation { duration: star.dur * 0.75 }
                        }
                    }
                }
            }
        }
    }

    Image {
        id: logo
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -parent.height * 0.02
        source: "images/logo.svg"
        sourceSize.width: Math.min(parent.width * 0.42, 900)
        opacity: 0
        OpacityAnimator on opacity { from: 0; to: 1; duration: 1400; running: true }
    }

    // saber progress line under the logo
    Rectangle {
        anchors.top: logo.bottom
        anchors.topMargin: parent.height * 0.04
        anchors.horizontalCenter: parent.horizontalCenter
        height: 4
        radius: 2
        width: Math.min(parent.width * 0.3, 520) * Math.min(1, root.stage / 6)
        color: "#f2fbff"
        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 6
            height: 10
            radius: 5
            color: "transparent"
            border.color: "#33b5ff"
            border.width: 3
            opacity: 0.8
        }
    }

    Rectangle {
        id: flashRect
        anchors.fill: parent
        color: "#e8f6ff"
        opacity: 0
        SequentialAnimation {
            id: flash
            NumberAnimation { target: flashRect; property: "opacity"; to: 0.55; duration: 140 }
            NumberAnimation { target: flashRect; property: "opacity"; to: 0; duration: 700 }
        }
    }
}
