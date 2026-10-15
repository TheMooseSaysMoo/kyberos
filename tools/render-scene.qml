// Render one wallpaper scene to a PNG at any size (used for the README previews):
//   QT_QPA_PLATFORM=offscreen qml tools/render-scene.qml -- <scene> <width> <height> <out.png> [crystal] [delayMs]
// after ./build/build.py has produced dist/. Offscreen, because a compositor clamps windows to the screen.
import QtQuick
import QtQuick.Window
import "../dist/plasma/wallpapers/org.kyberos.tactical/contents/ui" as K

Window {
    id: win
    readonly property var args: Qt.application.arguments.slice(Qt.application.arguments.indexOf("--") + 1)
    width: Number(args[1]); height: Number(args[2])
    visible: true
    color: "black"
    K.Backdrop {
        id: bd
        anchors.fill: parent
        scene: win.args[0]
        crystal: win.args[4] || "blue"
        animate: true
    }
    Timer {
        interval: Number(win.args[5] || 3500); running: true
        onTriggered: bd.grabToImage(function (r) { r.saveToFile(win.args[3]); Qt.quit() })
    }
}
