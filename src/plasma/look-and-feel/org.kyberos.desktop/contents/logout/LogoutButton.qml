/*
    KyberOS logout button: Breeze ActionButton on a chamfered steel plate.
    SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

import org.kde.kirigami as Kirigami

import org.kde.breeze.components
import "timer.js" as AutoTriggerTimer

ActionButton {
    id: btn
    readonly property bool lit: activeFocus || hovered
    readonly property real k: Kirigami.Units.gridUnit * 0.7

    Shape {
        z: -1
        anchors.fill: parent
        anchors.margins: -Kirigami.Units.smallSpacing
        ShapePath {
            strokeColor: btn.lit ? Kirigami.Theme.highlightColor : "#36414f"
            strokeWidth: btn.lit ? 2 : 1
            fillColor: btn.lit ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.14)
                               : Qt.rgba(0.1, 0.125, 0.16, 0.6)
            startX: btn.k; startY: 0
            PathLine { x: btn.width + 2 * Kirigami.Units.smallSpacing; y: 0 }
            PathLine { x: btn.width + 2 * Kirigami.Units.smallSpacing; y: btn.height + 2 * Kirigami.Units.smallSpacing - btn.k }
            PathLine { x: btn.width + 2 * Kirigami.Units.smallSpacing - btn.k; y: btn.height + 2 * Kirigami.Units.smallSpacing }
            PathLine { x: 0; y: btn.height + 2 * Kirigami.Units.smallSpacing }
            PathLine { x: 0; y: btn.k }
            PathLine { x: btn.k; y: 0 }
        }
    }
    // otherwise the Button color group is used
    // and text legibility is broken with light themes
    // which set their own color scheme
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary

    Layout.alignment: Qt.AlignTop

    icon.width: Kirigami.Units.iconSizes.huge
    icon.height: Kirigami.Units.iconSizes.huge

    font.underline: false // See https://phabricator.kde.org/D9452
    opacity: activeFocus || hovered ? 1 : 0.75

    Keys.onPressed: {
        AutoTriggerTimer.cancelAutoTrigger();
    }
}
