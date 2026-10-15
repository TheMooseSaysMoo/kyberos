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

    Sensors.Sensor { id: cpu; sensorId: "cpu/all/usage"; updateRateLimit: 1000 }
    Sensors.Sensor { id: mem; sensorId: "memory/physical/usedPercent"; updateRateLimit: 2000 }
    Sensors.Sensor { id: temp; sensorId: "cpu/all/maximumTemperature"; updateRateLimit: 2000 }
    Sensors.Sensor { id: gpu; sensorId: "gpu/all/usage"; updateRateLimit: 1000 }
    Sensors.Sensor { id: down; sensorId: "network/all/download"; updateRateLimit: 1000 }
    Sensors.Sensor { id: up; sensorId: "network/all/upload"; updateRateLimit: 1000 }
    Sensors.Sensor { id: cores; sensorId: "cpu/all/coreCount" }

    function pct(s) { return Math.max(0, Math.min(1, (s.value || 0) / 100)) }
    function rate(bytes) {
        const b = bytes || 0
        if (b > 1048576) return (b / 1048576).toFixed(1) + "M"
        if (b > 1024) return (b / 1024).toFixed(0) + "K"
        return b.toFixed(0) + "B"
    }

    toolTipMainText: "SHIP DIAGNOSTICS"
    toolTipSubText: "Reactor " + Math.round(cpu.value || 0) + "%  ·  Shields " + Math.round(mem.value || 0)
                    + "%  ·  Hull " + Math.round(temp.value || 0) + "°C"

    // ---- in the panel: three compact readouts ----
    compactRepresentation: MouseArea {
        Layout.minimumWidth: compactRow.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                model: [
                    { label: "RCT", value: () => root.pct(cpu) },
                    { label: "SHD", value: () => root.pct(mem) },
                    { label: "HUL", value: () => Math.min(1, (temp.value || 0) / 100) },
                ]
                ColumnLayout {
                    spacing: 1
                    PlasmaComponents3.Label {
                        text: modelData.label
                        font.family: root.headFont
                        font.pixelSize: Math.max(7, Kirigami.Units.gridUnit * 0.42)
                        font.letterSpacing: 1.5
                        opacity: 0.7
                    }
                    SegmentBar {
                        value: modelData.value()
                        segments: 8
                        segmentWidth: 4
                        segmentHeight: Math.max(5, Kirigami.Units.gridUnit * 0.35)
                    }
                }
            }
        }
    }

    // ---- popup: full console readout ----
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: implicitHeight
        spacing: Kirigami.Units.largeSpacing

        PlasmaComponents3.Label {
            text: "SHIP DIAGNOSTICS"
            font.family: root.headFont
            font.pixelSize: Kirigami.Units.gridUnit * 0.8
            font.letterSpacing: 4
            color: Kirigami.Theme.highlightColor
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.highlightColor; opacity: 0.6 }

        Repeater {
            model: [
                { label: "REACTOR OUTPUT", sensor: cpu, unit: "%", frac: () => root.pct(cpu), show: true },
                { label: "DEFLECTOR SHIELDS", sensor: mem, unit: "%", frac: () => root.pct(mem), show: true },
                { label: "TARGETING COMPUTER", sensor: gpu, unit: "%", frac: () => root.pct(gpu), show: gpu.status === Sensors.Sensor.Ready },
                { label: "HULL TEMPERATURE", sensor: temp, unit: "°C", frac: () => Math.min(1, (temp.value || 0) / 100), show: true },
            ]
            RowLayout {
                visible: modelData.show
                Layout.fillWidth: true
                PlasmaComponents3.Label {
                    text: modelData.label
                    font.family: root.headFont
                    font.pixelSize: Kirigami.Units.gridUnit * 0.55
                    font.letterSpacing: 2
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                    opacity: 0.85
                }
                SegmentBar {
                    value: modelData.frac()
                    segments: 14
                    segmentWidth: Kirigami.Units.gridUnit * 0.38
                    segmentHeight: Kirigami.Units.gridUnit * 0.6
                }
                PlasmaComponents3.Label {
                    text: Math.round(modelData.sensor.value || 0) + modelData.unit
                    font.family: root.monoFont
                    font.pixelSize: Kirigami.Units.gridUnit * 0.75
                    color: "#a6f2c4"
                    horizontalAlignment: Text.AlignRight
                    Layout.fillWidth: true
                }
            }
        }

        // per-core reactor cells
        PlasmaComponents3.Label {
            text: "REACTOR CELLS"
            font.family: root.headFont
            font.pixelSize: Kirigami.Units.gridUnit * 0.5
            font.letterSpacing: 2
            opacity: 0.6
        }
        Flow {
            Layout.fillWidth: true
            spacing: 3
            Repeater {
                model: Math.max(1, cores.value || 1)
                Rectangle {
                    Sensors.Sensor { id: core; sensorId: "cpu/cpu" + index + "/usage"; updateRateLimit: 1000 }
                    readonly property real load: Math.max(0, Math.min(1, (core.value || 0) / 100))
                    width: Kirigami.Units.gridUnit * 0.9
                    height: Kirigami.Units.gridUnit * 0.9
                    color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g,
                                   Kirigami.Theme.highlightColor.b, 0.12 + 0.88 * load)
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.15) }
        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents3.Label {
                text: "COMMS"
                font.family: root.headFont
                font.pixelSize: Kirigami.Units.gridUnit * 0.55
                font.letterSpacing: 2
                opacity: 0.85
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents3.Label {
                text: "▼ " + root.rate(down.value) + "/s   ▲ " + root.rate(up.value) + "/s"
                font.family: root.monoFont
                font.pixelSize: Kirigami.Units.gridUnit * 0.75
                color: "#a6f2c4"
            }
        }
    }
}
