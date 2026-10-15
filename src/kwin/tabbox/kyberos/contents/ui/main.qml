/*
    KyberOS window switcher (Alt+Tab): a targeting console. Windows sit in a
    strip of chamfered monitors; the selected one gets lock brackets.
    Based on the structure of KWin's thumbnail_grid switcher.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kwin as KWin
import org.kde.kirigami as Kirigami

KWin.TabBoxSwitcher {
    id: tabBox

    Instantiator {
        active: tabBox.visible
        delegate: PlasmaCore.Dialog {
            location: PlasmaCore.Types.Floating
            visible: true
            flags: Qt.Popup | Qt.X11BypassWindowManagerHint
            x: tabBox.screenGeometry.x + tabBox.screenGeometry.width * 0.5 - dialogMainItem.width * 0.5
            y: tabBox.screenGeometry.y + tabBox.screenGeometry.height * 0.5 - dialogMainItem.height * 0.5

            mainItem: FocusScope {
                id: dialogMainItem
                focus: true

                readonly property real screenFactor: tabBox.screenGeometry.width / tabBox.screenGeometry.height
                readonly property int thumbW: Kirigami.Units.gridUnit * 14
                readonly property int thumbH: Math.round(thumbW / screenFactor)
                readonly property int cellW: thumbW + Kirigami.Units.gridUnit * 1.5
                readonly property int maxWidth: tabBox.screenGeometry.width * 0.9
                readonly property color accent: Kirigami.Theme.highlightColor

                width: Math.max(Kirigami.Units.gridUnit * 22, Math.min(maxWidth, list.count * cellW + Kirigami.Units.gridUnit))
                height: header.height + thumbH + Kirigami.Units.gridUnit * 3.6

                // ---- header: SELECT TARGET ............ 03 / 07 ----
                RowLayout {
                    id: header
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Kirigami.Units.largeSpacing }
                    PlasmaComponents3.Label {
                        text: "SELECT TARGET"
                        font.family: "Michroma"
                        font.pixelSize: Kirigami.Units.gridUnit * 0.6
                        font.letterSpacing: 4
                        color: dialogMainItem.accent
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: dialogMainItem.accent; opacity: 0.4 }
                    PlasmaComponents3.Label {
                        text: String(list.currentIndex + 1).padStart(2, "0") + " / " + String(list.count).padStart(2, "0")
                        font.family: "Share Tech Mono"
                        font.pixelSize: Kirigami.Units.gridUnit * 0.75
                        color: "#a6f2c4"
                    }
                }

                ListView {
                    id: list
                    anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom
                              topMargin: Kirigami.Units.largeSpacing; leftMargin: Kirigami.Units.smallSpacing; rightMargin: Kirigami.Units.smallSpacing }
                    orientation: ListView.Horizontal
                    focus: true
                    clip: true
                    model: tabBox.model
                    currentIndex: tabBox.currentIndex
                    keyNavigationWraps: true
                    highlightMoveDuration: Kirigami.Units.shortDuration
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: width * 0.25
                    preferredHighlightEnd: width * 0.75
                    onCurrentIndexChanged: tabBox.currentIndex = currentIndex

                    delegate: MouseArea {
                        id: cell
                        width: dialogMainItem.cellW
                        height: list.height
                        hoverEnabled: true
                        readonly property bool current: ListView.isCurrentItem
                        onClicked: tabBox.model.activate(index)
                        Accessible.name: model.caption
                        Accessible.role: Accessible.ListItem

                        Item {
                            id: monitor
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: Kirigami.Units.smallSpacing
                            width: dialogMainItem.thumbW
                            height: dialogMainItem.thumbH
                            opacity: cell.current ? 1 : (cell.containsMouse ? 0.85 : 0.55)
                            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }

                            // chamfered steel bezel
                            Shape {
                                anchors.fill: parent
                                anchors.margins: -4
                                readonly property real k: 10
                                ShapePath {
                                    strokeColor: cell.current ? dialogMainItem.accent : "#36414f"
                                    strokeWidth: cell.current ? 2 : 1
                                    fillColor: "#06080b"
                                    startX: 10; startY: 0
                                    PathLine { x: monitor.width + 8; y: 0 }
                                    PathLine { x: monitor.width + 8; y: monitor.height + 8 - 10 }
                                    PathLine { x: monitor.width + 8 - 10; y: monitor.height + 8 }
                                    PathLine { x: 0; y: monitor.height + 8 }
                                    PathLine { x: 0; y: 10 }
                                    PathLine { x: 10; y: 0 }
                                }
                            }
                            KWin.WindowThumbnail {
                                anchors.fill: parent
                                wId: windowId
                            }
                            Kirigami.Icon {
                                anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: Kirigami.Units.smallSpacing
                                width: Kirigami.Units.iconSizes.medium; height: width
                                source: model.icon
                            }
                            // lock brackets on the selected target
                            Repeater {
                                model: cell.current ? [[0, 0], [1, 0], [0, 1], [1, 1]] : []
                                Shape {
                                    id: bracket
                                    x: modelData[0] * monitor.width
                                    y: modelData[1] * monitor.height
                                    readonly property real l: Kirigami.Units.gridUnit * 1.2
                                    readonly property real g: Kirigami.Units.gridUnit * 0.6
                                    readonly property real sx: modelData[0] ? 1 : -1
                                    readonly property real sy: modelData[1] ? 1 : -1
                                    ShapePath {
                                        strokeColor: "#ffb02e"; strokeWidth: 3; fillColor: "transparent"
                                        capStyle: ShapePath.SquareCap
                                        startX: bracket.sx * bracket.g; startY: bracket.sy * (bracket.g - bracket.l)
                                        PathLine { x: bracket.sx * bracket.g; y: bracket.sy * bracket.g }
                                        PathLine { x: bracket.sx * (bracket.g - bracket.l); y: bracket.sy * bracket.g }
                                    }
                                }
                            }
                        }
                        PlasmaComponents3.Label {
                            anchors { top: monitor.bottom; topMargin: Kirigami.Units.largeSpacing; horizontalCenter: parent.horizontalCenter }
                            width: dialogMainItem.thumbW
                            text: model.caption
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            font.family: cell.current ? "Share Tech Mono" : Kirigami.Theme.defaultFont.family
                            color: cell.current ? "#a6f2c4" : Kirigami.Theme.textColor
                            opacity: cell.current ? 1 : 0.7
                        }
                    }
                }

                Kirigami.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.largeSpacing * 2
                    icon.source: "edit-none"
                    text: "NO TARGETS"
                    visible: list.count === 0
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Left) {
                        list.decrementCurrentIndex()
                    } else if (event.key === Qt.Key_Right) {
                        list.incrementCurrentIndex()
                    } else {
                        return
                    }
                    tabBox.currentIndex = list.currentIndex
                }
            }

            onSceneGraphError: () => {}
        }
    }
}
