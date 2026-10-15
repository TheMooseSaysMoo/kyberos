/*
    KyberOS logout screen ("POWER SYSTEMS"), restyled from Breeze's Logout.qml.
    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Shapes

import org.kde.plasma.components as PlasmaComponents
import org.kde.coreaddons as KCoreAddons
import org.kde.kirigami as Kirigami

import org.kde.breeze.components
import "timer.js" as AutoTriggerTimer

import org.kde.plasma.private.sessions

Item {
    id: root
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    height: screenGeometry.height
    width: screenGeometry.width

    signal logoutRequested()
    signal haltRequested()
    signal haltUpdateRequested()
    signal suspendRequested(int spdMethod)
    signal rebootRequested()
    signal rebootRequested2(int opt)
    signal rebootUpdateRequested()
    signal cancelRequested()
    signal lockScreenRequested()
    signal cancelSoftwareUpdateRequested()

    function sleepRequested() {
        root.suspendRequested(2);
    }

    function hibernateRequested() {
        root.suspendRequested(4);
    }

    property real timeout: 30
    property real remainingTime: root.timeout

    property var currentAction: {
        switch (sdtype) {
        case ShutdownType.ShutdownTypeReboot:
            return () => softwareUpdatePending ? rebootUpdateRequested() : rebootRequested();
        case ShutdownType.ShutdownTypeHalt:
            return () => softwareUpdatePending ? haltUpdateRequested() : haltRequested();
        default:
            return () => logoutRequested();
        }
    }

    readonly property bool showAllOptions: sdtype === ShutdownType.ShutdownTypeDefault

    KCoreAddons.KUser {
        id: kuser
    }

    // For showing an "other users are logged in" hint
    SessionsModel {
        id: otherSessionsModel

        // In case the default values ever change
        includeUnusedSessions: false
        includeOwnSession: false
    }

    QQC2.Action {
        onTriggered: root.cancelRequested()
        shortcut: "Escape"
    }

    onRemainingTimeChanged: {
        if (remainingTime <= 0) {
            (currentAction)();
        }
    }

    Timer {
        id: countDownTimer
        running: !showAllOptions
        repeat: true
        interval: 1000
        onTriggered: remainingTime--
        Component.onCompleted: {
            AutoTriggerTimer.addCancelAutoTriggerCallback(function() {
                countDownTimer.running = false;
            });
        }
    }

    readonly property color accent: Kirigami.Theme.highlightColor

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: "#06080b"
        opacity: 0.9
    }
    Image {
        anchors.fill: parent
        source: "scan.svg"
        fillMode: Image.Tile
        sourceSize: Qt.size(4, 4)
    }
    // header: POWER SYSTEMS ------------------------------
    RowLayout {
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Kirigami.Units.gridUnit * 3 }
        spacing: Kirigami.Units.largeSpacing
        PlasmaComponents.Label {
            text: "POWER SYSTEMS"
            font.family: "Michroma"
            font.pixelSize: Kirigami.Units.gridUnit * 1.1
            font.letterSpacing: 8
            color: root.accent
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.accent; opacity: 0.5 }
        PlasmaComponents.Label {
            text: Qt.formatTime(new Date(), "HH:mm")
            font.family: "Share Tech Mono"
            font.pixelSize: Kirigami.Units.gridUnit * 1.1
            color: "#a6f2c4"
        }
    }
    Image {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Kirigami.Units.gridUnit * 2 }
        source: "../splash/images/logo.svg"
        sourceSize.width: Kirigami.Units.gridUnit * 14
        opacity: 0.55
    }
    MouseArea {
        anchors.fill: parent
        onClicked: root.cancelRequested()
    }
    Item {
        id: ring
        width: Kirigami.Units.gridUnit * 9
        height: width
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.verticalCenter; bottomMargin: Kirigami.Units.gridUnit * 1.1 }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: root.accent; strokeWidth: 3; fillColor: "transparent"
                strokeStyle: ShapePath.DashLine; dashPattern: [6, 4]
                PathAngleArc { centerX: ring.width / 2; centerY: ring.height / 2; radiusX: ring.width / 2 - 2; radiusY: ring.height / 2 - 2; startAngle: 0; sweepAngle: 300 }
            }
            RotationAnimator on rotation { from: 0; to: 360; duration: 12000; loops: Animation.Infinite }
        }
    }
    UserDelegate {
        width: Kirigami.Units.gridUnit * 8
        height: Kirigami.Units.gridUnit * 9
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.verticalCenter
        }
        constrainText: false
        avatarPath: kuser.faceIconUrl
        iconSource: "user-identity"
        isCurrent: true
        name: kuser.fullName
    }
    ColumnLayout {
        id: column

        anchors {
            top: parent.verticalCenter
            topMargin: Kirigami.Units.gridUnit * 2
            horizontalCenter: parent.horizontalCenter
        }
        spacing: Kirigami.Units.largeSpacing

        height: Math.max(implicitHeight, Kirigami.Units.gridUnit * 10)
        width: Math.max(implicitWidth, Kirigami.Units.gridUnit * 16)

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
            font.family: "Share Tech Mono"
            color: "#ffb02e"
            Layout.alignment: Qt.AlignHCenter
            //opacity, as visible would re-layout
            opacity: countDownTimer.running ? 1 : 0
            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
            text: {
                switch (sdtype) {
                    case ShutdownType.ShutdownTypeReboot:
                        return softwareUpdatePending ? i18ndp("plasma_lookandfeel_org.kde.lookandfeel", "Installing software updates and restarting in 1 second", "Installing software updates and restarting in %1 seconds", root.remainingTime)
                        : i18ndp("plasma_lookandfeel_org.kde.lookandfeel", "Restarting in 1 second", "Restarting in %1 seconds", root.remainingTime);
                    case ShutdownType.ShutdownTypeNone:
                        return i18ndp("plasma_lookandfeel_org.kde.lookandfeel", "Logging out in 1 second", "Logging out in %1 seconds", root.remainingTime);
                    case ShutdownType.ShutdownTypeHalt:
                    default:
                        return softwareUpdatePending ? i18ndp("plasma_lookandfeel_org.kde.lookandfeel", "Installing software updates and shutting down in 1 second", "Installing software updates and shutting down in %1 seconds", root.remainingTime)
                        : i18ndp("plasma_lookandfeel_org.kde.lookandfeel", "Shutting down in 1 second", "Shutting down in %1 seconds", root.remainingTime);
                }
            }
            textFormat: Text.PlainText
        }

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.maximumWidth: Math.max(Kirigami.Units.gridUnit * 16, logoutButtonsRow.implicitWidth)
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: true
            text: i18ndp("plasma_lookandfeel_org.kde.lookandfeel",
                         "One other user is currently logged in. If the computer is shut down or restarted, that user may lose work.",
                         "%1 other users are currently logged in. If the computer is shut down or restarted, those users may lose work.",
                         otherSessionsModel.count)
            textFormat: Text.PlainText
            visible: otherSessionsModel.count > 0 && (sdtype !== ShutdownType.ShutdownTypeNone || root.showAllOptions)
        }

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.maximumWidth: Math.max(Kirigami.Units.gridUnit * 16, logoutButtonsRow.implicitWidth)
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: true
            text: {
                if (isUefi) {
                    return i18nd("plasma_lookandfeel_org.kde.lookandfeel", "When restarted, the computer will enter UEFI firmware settings.");
                } else {
                    return i18nd("plasma_lookandfeel_org.kde.lookandfeel", "When restarted, the computer will enter the firmware setup screen.");
                }
            }
            textFormat: Text.PlainText
            visible: rebootToFirmwareSetup
        }

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.maximumWidth: Math.max(Kirigami.Units.gridUnit * 16, logoutButtonsRow.implicitWidth)
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: true
            text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "When restarted, the computer will enter the boot loader menu.")
            textFormat: Text.PlainText
            visible: rebootToBootLoaderMenu
        }

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.maximumWidth: Math.max(Kirigami.Units.gridUnit * 16, logoutButtonsRow.implicitWidth)
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: true
            text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "%1 is a boot loader entry", "When restarted, the computer will switch to %1.", rebootToBootLoaderEntry)
            textFormat: Text.PlainText
            visible: rebootToBootLoaderEntry != ""
        }

        GridLayout {
            id: logoutButtonsRow

            readonly property int spacing: Kirigami.Units.gridUnit
            rowSpacing: spacing
            columnSpacing: spacing

            Layout.topMargin: Kirigami.Units.gridUnit * 2 - column.spacing
            Layout.alignment: Qt.AlignHCenter

            readonly property int buttonCount: visibleChildren.length
            readonly property int singleRowWidth: (children[0].implicitWidth * buttonCount) + (spacing * (buttonCount - 1))
            columns: singleRowWidth < root.width ? buttonCount : Math.ceil(buttonCount / 2)

            LogoutButton {
                id: suspendButton
                icon.name: "system-suspend"
                text: root.showAllOptions ? i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Suspend to RAM", "Slee&p")
                                          : i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Suspend to RAM", "Slee&p Now")
                onClicked: root.sleepRequested()
                KeyNavigation.left: cancelButton
                KeyNavigation.right: hibernateButton.visible ? hibernateButton : (rebootButton.visible ? rebootButton : (shutdownButton.visible ? shutdownButton : (logoutButton.visible ? logoutButton : cancelButton)))
                visible: spdMethods.SuspendState && root.showAllOptions
            }
            LogoutButton {
                id: hibernateButton
                icon.name: "system-suspend-hibernate"
                text: root.showAllOptions ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Hibernate")
                                          : i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Hibernate Now")
                onClicked: root.hibernateRequested()
                KeyNavigation.left: suspendButton.visible ? suspendButton : cancelButton
                KeyNavigation.right: rebootButton.visible ? rebootButton : (shutdownButton.visible ? shutdownButton : (logoutButton.visible ? logoutButton : cancelButton))
                visible: spdMethods.HibernateState && root.showAllOptions
            }
            LogoutButton {
                id: rebootButton
                icon.name: softwareUpdatePending ? "system-reboot-update" : "system-reboot"
                text: {
                    if (softwareUpdatePending) {
                        return i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "@action:button Keep short", "Install Updates and Restart")
                    } else {
                        return root.showAllOptions ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Restart")
                                                   : i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Restart Now")
                    }
                }
                onClicked: {
                    if (softwareUpdatePending) {
                        root.rebootUpdateRequested();
                    } else {
                        root.rebootRequested();
                    }
                }
                KeyNavigation.left: hibernateButton.visible ? hibernateButton : (suspendButton.visible ? suspendButton : cancelButton)
                KeyNavigation.right: rebootWithoutUpdatesButton.visible ? rebootWithoutUpdatesButton : (shutdownButton.visible ? shutdownButton : (logoutButton.visible ? logoutButton : cancelButton))
                focus: sdtype === ShutdownType.ShutdownTypeReboot
                visible: maysd && (sdtype === ShutdownType.ShutdownTypeReboot || root.showAllOptions)
            }
            LogoutButton {
                id: rebootWithoutUpdatesButton
                icon.name: "system-reboot"
                text: root.showAllOptions ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Restart")
                                          : i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Restart Now")
                onClicked: {
                    root.rebootRequested();
                }
                KeyNavigation.left: rebootButton
                KeyNavigation.right: shutdownButton.visible ? shutdownButton : (logoutButton.visible ? logoutButton : cancelButton)
                visible: maysd && softwareUpdatePending && (sdtype === ShutdownType.ShutdownTypeReboot || root.showAllOptions)
            }
            LogoutButton {
                id: shutdownButton
                icon.name: softwareUpdatePending ? "system-shutdown-update" : "system-shutdown"
                text: {
                    if (softwareUpdatePending) {
                        return i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "@action:button Keep short", "Install Updates and Shut Down")
                    } else {
                        return root.showAllOptions ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Shut Down")
                                                   : i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Shut Down Now")
                    }
                }
                onClicked: {
                    if (softwareUpdatePending) {
                        root.haltUpdateRequested();
                    } else {
                        root.haltRequested();
                    }
                }
                KeyNavigation.left: rebootWithoutUpdatesButton.visible ? rebootWithoutUpdatesButton : (rebootButton.visible ? rebootButton : (hibernateButton.visible ? hibernateButton : (suspendButton.visible ? suspendButton : cancelButton)))
                KeyNavigation.right: shutdownWithoutUpdatesButton.visible ? shutdownWithoutUpdatesButton : (logoutButton.visible ? logoutButton : cancelButton)
                focus: sdtype === ShutdownType.ShutdownTypeHalt || root.showAllOptions
                visible: maysd && (sdtype === ShutdownType.ShutdownTypeHalt || root.showAllOptions)
            }
            LogoutButton {
                id: shutdownWithoutUpdatesButton
                icon.name: "system-shutdown"
                text: root.showAllOptions ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Shut Down")
                                          : i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Shut Down Now")
                onClicked: {
                    root.haltRequested();
                }
                KeyNavigation.left: shutdownButton
                KeyNavigation.right: logoutButton.visible ? logoutButton : cancelButton
                focus: sdtype === ShutdownType.ShutdownTypeHalt || root.showAllOptions
                visible: maysd && softwareUpdatePending && (sdtype === ShutdownType.ShutdownTypeHalt || root.showAllOptions)
            }
            LogoutButton {
                id: logoutButton
                icon.name: "system-log-out"
                text: root.showAllOptions ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Log Out")
                                          : i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Log Out Now")
                onClicked: root.logoutRequested()
                KeyNavigation.left: shutdownWithoutUpdatesButton.visible ? shutdownWithoutUpdatesButton : (shutdownButton.visible ? shutdownButton : (rebootWithoutUpdatesButton.visible ? rebootWithoutUpdatesButton : (rebootButton.visible ? rebootButton : (hibernateButton.visible ? hibernateButton : (suspendButton.visible ? suspendButton : cancelButton)))))
                KeyNavigation.right: cancelButton
                focus: sdtype === ShutdownType.ShutdownTypeNone
                visible: canLogout && (sdtype === ShutdownType.ShutdownTypeNone || root.showAllOptions)
            }
            LogoutButton {
                id: cancelButton
                icon.name: "dialog-cancel"
                text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Cancel")
                onClicked: root.cancelRequested()
                KeyNavigation.left: logoutButton.visible ? logoutButton : (shutdownWithoutUpdatesButton.visible ? shutdownWithoutUpdatesButton : (shutdownButton.visible ? shutdownButton : (rebootWithoutUpdatesButton.visible ? rebootWithoutUpdatesButton : (rebootButton.visible ? rebootButton : (hibernateButton.visible ? hibernateButton : suspendButton)))))
                KeyNavigation.right: suspendButton.visible ? suspendButton : (hibernateButton.visible ? hibernateButton : rebootButton)
            }
        }
    }
}
