/*
    KyberOS SDDM login theme: the animated tactical backdrop on every screen and an
    "IDENTIFY" console on the primary one. Plain QtQuick + Shapes (no Plasma/Controls
    imports), so it runs in sddm-greeter-qt6 on any distro.
    SDDM context: sddm, userModel, sessionModel, config, keyboard, primaryScreen.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Shapes
import QtQuick.Window
import "ui"

Item {
    id: root
    width: Screen.width
    height: Screen.height

    readonly property string crystal: config.Crystal || "blue"
    readonly property bool animate: (config.Animate || "true") !== "false"
    readonly property color accent: backdrop.accent
    readonly property color amber: "#ffb02e"
    readonly property color alert: "#ff3b2f"
    readonly property color phosphor: "#a6f2c4"
    readonly property color text: "#d6dee8"
    readonly property color dim: "#8793a3"
    readonly property real u: Math.min(width, height)
    readonly property bool primary: typeof primaryScreen === "undefined" || primaryScreen

    property int userIndex: Math.max(0, userModel.lastIndex)
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)
    readonly property var userItem: users.count > 0 ? users.itemAt(Math.min(userIndex, users.count - 1)) : null
    readonly property string userName: userItem ? userItem.uname : (userModel.lastUser || "")

    Backdrop {
        id: backdrop
        anchors.fill: parent
        crystal: root.crystal
        animate: root.animate
        scene: {
            if (height > width * 1.1) {
                const mid = Screen.virtualX + Screen.width / 2
                return mid < Screen.desktopAvailableWidth / 2 ? "targeting" : "comms"
            }
            return "tactical"
        }
    }

    // names for the user/session pickers
    Repeater { id: users; model: userModel; Item { readonly property string uname: model.name; readonly property string real: model.realName || "" } }
    Repeater { id: sessions; model: sessionModel; Item { readonly property string sname: model.name } }

    // ---- clock -------------------------------------------------------------
    Text {
        id: clock
        visible: root.primary
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.u * 0.06
        color: root.text
        font.family: "Michroma"
        font.pixelSize: root.u * 0.05
        font.letterSpacing: root.u * 0.004
        text: Qt.formatTime(new Date(), "HH:mm")
        Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.text = Qt.formatTime(new Date(), "HH:mm") }
    }
    Text {
        visible: root.primary
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: clock.bottom
        color: root.dim
        font.family: "Share Tech Mono"
        font.pixelSize: root.u * 0.016
        font.letterSpacing: 3
        text: (sddm.hostName ? sddm.hostName.toUpperCase() + "  //  " : "") + Qt.formatDate(new Date(), "yyyy-MM-dd")
    }

    // ---- IDENTIFY console ------------------------------------------------------
    Item {
        id: panel
        visible: root.primary
        width: Math.min(root.width * 0.86, root.u * 0.62)
        height: col.implicitHeight + root.u * 0.07
        // landscape: sit in the open space left of the planet; portrait: centred
        readonly property real cx: root.width > root.height * 1.3 ? root.width * 0.3 : root.width * 0.5
        anchors.horizontalCenter: parent.left
        anchors.horizontalCenterOffset: cx
        y: root.height * 0.44 - height / 2
        readonly property real cut: root.u * 0.018

        Plate { anchors.fill: parent; cut: panel.cut; stroke: root.accent; fill: Qt.rgba(0.024, 0.031, 0.043, 0.86) }

        Column {
            id: col
            anchors.centerIn: parent
            width: parent.width - root.u * 0.07
            spacing: root.u * 0.022

            Row {
                width: parent.width
                spacing: root.u * 0.012
                Text {
                    id: title
                    text: "IMPERIAL NETWORK  //  IDENTIFY"
                    color: root.amber
                    font.family: "Orbitron"; font.weight: Font.DemiBold
                    font.pixelSize: root.u * 0.019; font.letterSpacing: root.u * 0.004
                }
                Rectangle { width: parent.width - title.width - parent.spacing; height: 1; color: root.amber; opacity: 0.4; anchors.verticalCenter: title.verticalCenter }
            }

            // operator (user) picker
            Item {
                width: parent.width; height: root.u * 0.05
                Arrow { back: true; visible: users.count > 1; anchors.left: parent.left; onActivated: root.userIndex = (root.userIndex + users.count - 1) % users.count }
                Column {
                    anchors.centerIn: parent
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "OPERATOR"
                        color: root.dim; font.family: "Share Tech Mono"; font.pixelSize: root.u * 0.013; font.letterSpacing: 4
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.userItem && root.userItem.real ? root.userItem.real : root.userName
                        color: root.text; font.family: "Michroma"; font.pixelSize: root.u * 0.024
                    }
                }
                Arrow { visible: users.count > 1; anchors.right: parent.right; onActivated: root.userIndex = (root.userIndex + 1) % users.count }
            }

            // access code
            Item {
                id: field
                width: parent.width; height: root.u * 0.058
                Plate { anchors.fill: parent; cut: root.u * 0.01; stroke: password.activeFocus ? root.accent : "#36414f"; fill: "#06080b" }
                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: root.u * 0.02; anchors.rightMargin: root.u * 0.02
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "◆"
                    color: root.phosphor
                    selectionColor: root.accent
                    font.family: "Share Tech Mono"; font.pixelSize: root.u * 0.024; font.letterSpacing: 6
                    focus: root.primary
                    clip: true
                    onAccepted: root.login()
                    Keys.onEscapePressed: text = ""
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter; x: root.u * 0.02
                    visible: password.text.length === 0
                    text: "ACCESS CODE"
                    color: root.dim; opacity: 0.6
                    font.family: "Share Tech Mono"; font.pixelSize: root.u * 0.02; font.letterSpacing: 4
                }
                MouseArea { anchors.fill: parent; onClicked: password.forceActiveFocus(); cursorShape: Qt.IBeamCursor }
            }

            // status line
            Text {
                id: status
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.family: "Share Tech Mono"; font.pixelSize: root.u * 0.015; font.letterSpacing: 3
                color: root.phase === "denied" ? root.alert : (keyboard.capsLock ? root.amber : root.dim)
                text: root.phase === "denied" ? "ACCESS DENIED  //  RE-ENTER CODE"
                    : root.phase === "busy" ? "VERIFYING ..."
                    : keyboard.capsLock ? "CAPS LOCK ENGAGED"
                    : "AWAITING CREDENTIALS"
            }
        }

        SequentialAnimation {
            id: shake
            NumberAnimation { target: panel; property: "anchors.horizontalCenterOffset"; to: panel.cx - root.u * 0.012; duration: 50 }
            NumberAnimation { target: panel; property: "anchors.horizontalCenterOffset"; to: panel.cx + root.u * 0.012; duration: 70 }
            NumberAnimation { target: panel; property: "anchors.horizontalCenterOffset"; to: panel.cx - root.u * 0.006; duration: 60 }
            NumberAnimation { target: panel; property: "anchors.horizontalCenterOffset"; to: panel.cx; duration: 50 }
        }
    }

    // ---- session (bottom left) + power (bottom right) ---------------------------------
    TextButton {
        visible: root.primary && sessions.count > 0
        anchors.left: parent.left; anchors.bottom: parent.bottom
        anchors.margins: root.u * 0.05
        label: "SESSION  " + (sessions.count > 0 && sessions.itemAt(Math.min(root.sessionIndex, sessions.count - 1))
                              ? sessions.itemAt(Math.min(root.sessionIndex, sessions.count - 1)).sname.toUpperCase() : "") + "  ▸"
        onActivated: root.sessionIndex = (root.sessionIndex + 1) % sessions.count
    }
    Row {
        visible: root.primary
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: root.u * 0.05
        spacing: root.u * 0.03
        TextButton { visible: sddm.canSuspend; label: "SUSPEND"; onActivated: sddm.suspend() }
        TextButton { visible: sddm.canReboot; label: "RESTART"; onActivated: sddm.reboot() }
        TextButton { visible: sddm.canPowerOff; label: "SHUT DOWN"; colour: root.alert; onActivated: sddm.powerOff() }
    }

    property string phase: ""     // "" | busy | denied
    function login() {
        if (root.phase === "busy") return
        root.phase = "busy"
        sddm.login(root.userName, password.text, root.sessionIndex)
    }
    Connections {
        target: sddm
        function onLoginFailed() { root.phase = "denied"; password.text = ""; password.forceActiveFocus(); shake.restart() }
        function onLoginSucceeded() { root.phase = "busy" }
    }

    // ---- small building blocks -----------------------------------------------------
    component Plate: Shape {
        id: plate
        property real cut: 10
        property color stroke: "#36414f"
        property color fill: "transparent"
        ShapePath {
            strokeColor: plate.stroke; strokeWidth: 2; fillColor: plate.fill
            startX: plate.cut; startY: 0
            PathLine { x: plate.width; y: 0 }
            PathLine { x: plate.width; y: plate.height - plate.cut }
            PathLine { x: plate.width - plate.cut; y: plate.height }
            PathLine { x: 0; y: plate.height }
            PathLine { x: 0; y: plate.cut }
            PathLine { x: plate.cut; y: 0 }
        }
    }
    component TextButton: Text {
        id: tb
        property string label
        property color colour: root.text
        signal activated()
        text: label
        color: ma.containsMouse ? root.accent : colour
        opacity: ma.containsMouse ? 1 : 0.8
        font.family: "Share Tech Mono"; font.pixelSize: root.u * 0.016; font.letterSpacing: 3
        MouseArea { id: ma; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tb.activated() }
    }
    component Arrow: Text {
        id: ar
        property bool back: false
        signal activated()
        anchors.verticalCenter: parent.verticalCenter
        text: back ? "◂" : "▸"
        color: am.containsMouse ? root.accent : root.dim
        font.pixelSize: root.u * 0.03
        MouseArea { id: am; anchors.fill: parent; anchors.margins: -10; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ar.activated() }
    }
}
