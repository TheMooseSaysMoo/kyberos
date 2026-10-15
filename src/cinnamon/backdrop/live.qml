/*
    KyberOS live backdrop for Cinnamon (opt-in): one borderless desktop-layer window per
    monitor running the animated scene, below the desktop icons.
      qml live.qml -- <crystal>
    Started by kyberos-live (user service). SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQml
import QtQuick
import QtQuick.Window
import "ui"

QtObject {
    id: app
    readonly property string crystal: Qt.application.arguments[Qt.application.arguments.length - 1]
    readonly property int desktopWidth: {
        let w = 0
        for (const s of Qt.application.screens) w = Math.max(w, s.virtualX + s.width)
        return w
    }

    property Instantiator windows: Instantiator {
        model: Qt.application.screens
        delegate: Window {
            required property var modelData
            screen: modelData
            x: modelData.virtualX; y: modelData.virtualY
            width: modelData.width; height: modelData.height
            title: "kyberos-live"
            color: "#06080b"
            flags: Qt.Desktop | Qt.FramelessWindowHint | Qt.WindowStaysOnBottomHint | Qt.WindowDoesNotAcceptFocus
            visible: true
            Backdrop {
                anchors.fill: parent
                crystal: app.crystal
                animate: true
                scene: {
                    if (height > width * 1.1)
                        return modelData.virtualX + modelData.width / 2 < app.desktopWidth / 2 ? "targeting" : "comms"
                    return "tactical"
                }
            }
        }
    }
}
