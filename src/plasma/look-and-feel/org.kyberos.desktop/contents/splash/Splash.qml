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

        Repeater {
            model: 140
            Item {
                id: star
                readonly property real angle: (index * 137.508) % 360
                readonly property real speed: 0.6 + ((index * 53) % 100) / 110
                property real d: ((index * 97) % 100) / 100 * field.maxD
                x: field.width / 2
                y: field.height / 2
                rotation: angle

                Rectangle {
                    // streak grows with distance and warp
                    readonly property real len: 2 + star.d * (0.02 + root.warp * 0.28) * star.speed
                    x: star.d - len
                    y: -1
                    width: len
                    height: 2
                    radius: 1
                    opacity: Math.min(1, star.d / 140)
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.7; color: "#9fd8ff" }
                        GradientStop { position: 1.0; color: "#ffffff" }
                    }
                }

                NumberAnimation on d {
                    id: fly
                    from: 6
                    to: field.maxD
                    duration: (5200 - root.warp * 4200) / star.speed
                    easing.type: Easing.InQuad
                    loops: Animation.Infinite
                    running: true
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
