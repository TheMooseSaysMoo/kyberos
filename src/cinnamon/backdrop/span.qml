/*
    Render every monitor's scene into ONE image laid out like the desktop, for Cinnamon's
    "spanned" background (Cinnamon can't run animated wallpapers).
      QT_QPA_PLATFORM=offscreen qml span.qml -- <out.png> <W> <H> <crystal> <x,y,w,h,scene>...
    Used by kyberos-wallpaper. SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Window
import "ui"

Window {
    id: win
    readonly property var args: Qt.application.arguments.slice(Qt.application.arguments.indexOf("--") + 1)
    readonly property var mons: args.slice(4).map(s => {
        const f = s.split(",")
        return { x: Number(f[0]), y: Number(f[1]), w: Number(f[2]), h: Number(f[3]), scene: f[4] }
    })
    width: Number(args[1])
    height: Number(args[2])
    visible: true
    color: "#06080b"

    Item {
        id: canvas
        anchors.fill: parent
        Repeater {
            model: win.mons
            Backdrop {
                x: modelData.x; y: modelData.y
                width: modelData.w; height: modelData.h
                clip: true             // scenes may draw past their edges (each is its own window on Plasma)
                scene: modelData.scene
                crystal: win.args[3]
                animate: true          // let the scene settle into a representative frame
                still: true
            }
        }
    }
    Timer {
        interval: 2500; running: true
        onTriggered: canvas.grabToImage(r => { r.saveToFile(win.args[0]); Qt.quit() })
    }
}
