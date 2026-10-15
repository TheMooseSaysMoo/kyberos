/*
    Segmented readout bar, Imperial console style. value is 0..1.
    Give it a width (e.g. Layout.fillWidth) and the segments share it;
    otherwise it sizes itself from segmentWidth.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: bar
    property real value: 0
    property bool active: true          // false = sensor missing: all segments dark
    property int segments: 10
    property real segmentWidth: 5
    property real segmentHeight: 8
    property real gap: 2
    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property color warn: "#ffb02e"
    readonly property color alarm: "#ff3b2f"
    readonly property real cell: width > 0 ? (width - gap * (segments - 1)) / segments : segmentWidth

    implicitWidth: segments * segmentWidth + gap * (segments - 1)
    implicitHeight: segmentHeight

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: bar.gap
        Repeater {
            model: bar.segments
            Rectangle {
                readonly property real threshold: (index + 1) / bar.segments
                readonly property bool lit: bar.active && bar.value >= threshold - 0.5 / bar.segments
                width: Math.max(1, bar.cell)
                height: bar.segmentHeight
                color: !lit ? Qt.rgba(1, 1, 1, 0.08)
                     : threshold > 0.9 ? bar.alarm
                     : threshold > 0.75 ? bar.warn
                     : bar.accent
                Behavior on color { ColorAnimation { duration: 180 } }
            }
        }
    }
}
