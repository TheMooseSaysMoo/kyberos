/*
    KyberOS Ship Diagnostics.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    readonly property string monoFont: "Share Tech Mono"
    readonly property string headFont: "Michroma"
    readonly property real labelSize: Kirigami.Units.gridUnit * 0.5
    readonly property real valueSize: Kirigami.Units.gridUnit * 0.75

    Sensors.Sensor { id: cpu; sensorId: "cpu/all/usage"; updateRateLimit: 1000 }
    Sensors.Sensor { id: mem; sensorId: "memory/physical/usedPercent"; updateRateLimit: 2000 }
    Sensors.Sensor { id: temp; sensorId: "cpu/all/maximumTemperature"; updateRateLimit: 2000 }
    Sensors.Sensor { id: gpu; sensorId: "gpu/all/usage"; updateRateLimit: 1000 }
    Sensors.Sensor { id: down; sensorId: "network/all/download"; updateRateLimit: 1000 }
    Sensors.Sensor { id: up; sensorId: "network/all/upload"; updateRateLimit: 1000 }
    Sensors.Sensor { id: cores; sensorId: "cpu/all/coreCount" }

    // a sensor that reports nothing (e.g. no temperature probe in a VM) shows "--"
    function has(s) { return s.status === Sensors.Sensor.Ready && (s.value || 0) > 0 }
    function pct(s) { return Math.max(0, Math.min(1, (s.value || 0) / 100)) }
    function rate(bytes) {
        const b = bytes || 0
        if (b > 1048576) return (b / 1048576).toFixed(1) + "M"
        if (b > 1024) return (b / 1024).toFixed(0) + "K"
        return b.toFixed(0) + "B"
    }

    readonly property var readouts: [
        { label: "REACTOR OUTPUT", short: "RCT", sensor: cpu, unit: "%", scale: 100, always: true },
        { label: "DEFLECTOR SHIELDS", short: "SHD", sensor: mem, unit: "%", scale: 100, always: true },
        { label: "TARGETING COMPUTER", short: "TGT", sensor: gpu, unit: "%", scale: 100, always: false },
        { label: "HULL TEMPERATURE", short: "HUL", sensor: temp, unit: "°C", scale: 100, always: true },
    ]

    toolTipMainText: "SHIP DIAGNOSTICS"
    toolTipSubText: "Reactor " + Math.round(cpu.value || 0) + "%  ·  Shields " + Math.round(mem.value || 0) + "%"
                    + (has(temp) ? "  ·  Hull " + Math.round(temp.value) + "°C" : "")

    // ---- in the panel: three compact readouts ----
    compactRepresentation: MouseArea {
        id: compact
        readonly property real unit: Math.min(height, Kirigami.Units.gridUnit * 1.6)
        Layout.minimumWidth: compactRow.implicitWidth + Kirigami.Units.largeSpacing
        Layout.preferredWidth: Layout.minimumWidth
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                model: [root.readouts[0], root.readouts[1], root.readouts[3]]
                ColumnLayout {
                    spacing: Math.round(compact.unit * 0.08)
                    PlasmaComponents3.Label {
                        text: modelData.short
                        font.family: root.headFont
                        font.pixelSize: Math.max(7, Math.round(compact.unit * 0.3))
                        font.letterSpacing: 1
                        opacity: 0.75
                        Layout.alignment: Qt.AlignLeft
                    }
                    SegmentBar {
                        segments: 8
                        segmentWidth: Math.max(3, Math.round(compact.unit * 0.18))
                        segmentHeight: Math.max(4, Math.round(compact.unit * 0.22))
                        active: root.has(modelData.sensor)
                        value: Math.min(1, (modelData.sensor.value || 0) / modelData.scale)
                    }
                }
            }
        }
    }

    // ---- popup: full console readout ----
    fullRepresentation: ColumnLayout {
        id: full
        spacing: Kirigami.Units.largeSpacing
        Layout.minimumWidth: Kirigami.Units.gridUnit * 22
        Layout.preferredWidth: Kirigami.Units.gridUnit * 24
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight

        // measure the widest label/value in the real font so columns never collide
        PlasmaComponents3.Label {
            id: labelProbe
            visible: false
            text: "TARGETING COMPUTER"
            font.family: root.headFont
            font.pixelSize: root.labelSize
            font.letterSpacing: 2
        }
        PlasmaComponents3.Label {
            id: valueProbe
            visible: false
            text: "100°C"
            font.family: root.monoFont
            font.pixelSize: root.valueSize
        }

        PlasmaComponents3.Label {
            text: "SHIP DIAGNOSTICS"
            font.family: root.headFont
            font.pixelSize: Kirigami.Units.gridUnit * 0.8
            font.letterSpacing: 4
            color: Kirigami.Theme.highlightColor
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Kirigami.Theme.highlightColor; opacity: 0.6 }

        Repeater {
            model: root.readouts
            RowLayout {
                visible: modelData.always || root.has(modelData.sensor)
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                PlasmaComponents3.Label {
                    text: modelData.label
                    font: labelProbe.font
                    opacity: 0.85
                    Layout.preferredWidth: labelProbe.implicitWidth
                    Layout.minimumWidth: labelProbe.implicitWidth
                }
                SegmentBar {
                    Layout.fillWidth: true
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 5
                    segments: 14
                    segmentHeight: Kirigami.Units.gridUnit * 0.55
                    active: root.has(modelData.sensor)
                    value: Math.min(1, (modelData.sensor.value || 0) / modelData.scale)
                }
                PlasmaComponents3.Label {
                    text: root.has(modelData.sensor) ? Math.round(modelData.sensor.value) + modelData.unit : "--"
                    font: valueProbe.font
                    color: "#a6f2c4"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: valueProbe.implicitWidth
                    Layout.minimumWidth: valueProbe.implicitWidth
                }
            }
        }

        // per-core reactor cells
        PlasmaComponents3.Label {
            text: "REACTOR CELLS"
            font: labelProbe.font
            opacity: 0.6
            Layout.topMargin: Kirigami.Units.smallSpacing
        }
        Flow {
            id: cells
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            spacing: 3
            Repeater {
                model: Math.max(1, cores.value || 1)
                Rectangle {
                    Sensors.Sensor { id: core; sensorId: "cpu/cpu" + index + "/usage"; updateRateLimit: 1000 }
                    readonly property real load: Math.max(0, Math.min(1, (core.value || 0) / 100))
                    width: Kirigami.Units.gridUnit * 0.9
                    height: width
                    color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g,
                                   Kirigami.Theme.highlightColor.b, 0.12 + 0.88 * load)
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(1, 1, 1, 0.15) }
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.largeSpacing
            PlasmaComponents3.Label {
                text: "COMMS"
                font: labelProbe.font
                opacity: 0.85
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents3.Label {
                text: "▼ " + root.rate(down.value) + "/s   ▲ " + root.rate(up.value) + "/s"
                font: valueProbe.font
                color: "#a6f2c4"
            }
        }
    }
}
