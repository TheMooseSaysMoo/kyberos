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

// the qml runtime wants a window as root: an invisible one that owns the per-monitor windows
Window {
    id: app
    visible: false
    width: 1; height: 1
    readonly property string crystal: Qt.application.arguments[Qt.application.arguments.length - 1]
    readonly property int desktopWidth: {
        let w = 0
        const ss = Qt.application.screens          // a QML list: not iterable with for..of on Qt 6.4
        for (let i = 0; i < ss.length; i++) w = Math.max(w, ss[i].virtualX + ss[i].width)
        return w
    }

    Instantiator {
        model: Qt.application.screens
        delegate: Window {
            required property var modelData
            screen: modelData
            x: modelData.virtualX; y: modelData.virtualY
            width: modelData.width; height: modelData.height
            title: "kyberos-live"
            color: "#06080b"
            // (kyberos-live marks these _NET_WM_WINDOW_TYPE_DESKTOP once mapped: Qt.Desktop windows never show)
            flags: Qt.FramelessWindowHint | Qt.WindowStaysOnBottomHint | Qt.WindowDoesNotAcceptFocus
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
