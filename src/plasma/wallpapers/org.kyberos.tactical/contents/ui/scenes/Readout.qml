/*
    Block of pseudo-data rows: a lit marker plus bars of varying length.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import "geo.js" as Geo

Column {
    id: readout
    property color colour: "#a6f2c4"
    property int rows: 5
    property real rowHeight: 10
    property real barWidth: 220
    property int seed: 1
    property bool animate: true
    spacing: rowHeight * 0.55

    Repeater {
        model: readout.rows
        Row {
            id: row
            spacing: readout.rowHeight * 0.5
            readonly property var widths: {
                var r = Geo.rng(readout.seed * 97 + index * 13)
                var out = [], used = 0
                while (true) {
                    var w = readout.rowHeight * [1.2, 2, 3, 4.5, 6][Math.floor(r() * 5)]
                    if (used + w > readout.barWidth) break
                    out.push({ w: w, o: [0.25, 0.4, 0.65][Math.floor(r() * 3)] })
                    used += w + readout.rowHeight * 0.5
                }
                return out
            }
            Rectangle { width: readout.rowHeight * 0.5; height: readout.rowHeight; color: readout.colour }
            Repeater {
                model: row.widths
                Rectangle {
                    y: readout.rowHeight * 0.3
                    width: modelData.w
                    height: readout.rowHeight * 0.4
                    color: readout.colour
                    opacity: modelData.o
                }
            }
            // a cursor that occasionally rewrites the row
            SequentialAnimation {
                loops: Animation.Infinite
                running: readout.animate
                PauseAnimation { duration: 2500 + ((readout.seed * 7 + index * 1311) % 6000) }
                OpacityAnimator { target: row; to: 0.2; duration: 90 }
                OpacityAnimator { target: row; to: 1.0; duration: 260 }
            }
        }
    }
}
