/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property string cfg_Crystal
    property alias cfg_Banner: bannerField.text
    property alias cfg_Animate: animateBox.checked
    property alias cfg_SweepSeconds: sweepSpin.value

    readonly property var crystals: ["blue", "green", "red", "purple", "yellow", "white"]

    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Kyber crystal:")
        model: page.crystals.map(c => c.charAt(0).toUpperCase() + c.slice(1))
        currentIndex: Math.max(0, page.crystals.indexOf(page.cfg_Crystal))
        onActivated: index => page.cfg_Crystal = page.crystals[index]
    }
    QQC2.TextField {
        id: bannerField
        Kirigami.FormData.label: i18n("Banner:")
        placeholderText: i18n("e.g. AUTHORIZATION REQUIRED")
    }
    QQC2.CheckBox {
        id: animateBox
        Kirigami.FormData.label: i18n("Animation:")
        text: i18n("Radar sweep, scan line and status lights")
    }
    QQC2.SpinBox {
        id: sweepSpin
        Kirigami.FormData.label: i18n("Radar revolution (s):")
        from: 2; to: 60
        enabled: animateBox.checked
    }
}
