/*
    Segmented readout bar, Imperial console style. value is 0..1.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import org.kde.kirigami as Kirigami

Row {
    id: bar
    property real value: 0
    property int segments: 10
    property real segmentWidth: 5
    property real segmentHeight: 8
    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property color warn: "#ffb02e"
    readonly property color alarm: "#ff3b2f"
    spacing: 2

    Repeater {
        model: bar.segments
        Rectangle {
            readonly property real threshold: (index + 1) / bar.segments
            readonly property bool lit: bar.value >= threshold - 0.5 / bar.segments
            width: bar.segmentWidth
            height: bar.segmentHeight
            color: !lit ? Qt.rgba(1, 1, 1, 0.08)
                 : threshold > 0.9 ? bar.alarm
                 : threshold > 0.75 ? bar.warn
                 : bar.accent
            Behavior on color { ColorAnimation { duration: 180 } }
        }
    }
}
