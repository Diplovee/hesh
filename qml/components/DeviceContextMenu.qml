import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hesh 1.0

Popup {
    id: root

    property var manager
    property string deviceId: ""
    property string deviceName: ""
    property string deviceType: "web"
    property string deviceStatus: "Stopped"
    property string devicePresentationState: "Embedded"
    readonly property bool isWebDevice: root.deviceType === "web"
    readonly property bool isStandalone: root.devicePresentationState === "Standalone"
    readonly property bool deviceLocked: root.deviceType === "android"
                                         && root.manager
                                         && !root.manager.androidFeatureEnabled

    parent: Overlay.overlay
    width: 276
    padding: 7
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: Theme.panelRaised
        border.width: 1
        border.color: Theme.borderStrong
        radius: Theme.radiusSmall
    }

    function openFor(anchor) {
        openAt(anchor, 0, anchor.height + 5)
    }

    function openAt(anchor, localX, localY) {
        const point = anchor.mapToItem(Overlay.overlay, localX, localY)
        x = Math.max(10, Math.min(point.x, Overlay.overlay.width - width - 10))
        y = Math.max(10, Math.min(point.y, Overlay.overlay.height - height - 10))
        open()
    }

    function toggleDevice() {
        if (!root.manager || root.deviceId.length === 0) {
            return
        }
        if (root.deviceStatus === "Running") {
            root.manager.stopDevice(root.deviceId)
        } else {
            root.manager.startDevice(root.deviceId)
        }
        close()
    }

    function removeDevice() {
        if (root.manager && root.deviceId.length > 0) {
            root.manager.removeDevice(root.deviceId)
        }
        close()
    }

    function reloadDevice(hardReload) {
        if (root.manager && root.deviceId.length > 0)
            root.manager.reloadDevice(root.deviceId, hardReload)
        close()
    }

    function toggleStandalone() {
        if (!root.manager || !root.isWebDevice || root.deviceId.length === 0)
            return
        if (root.isStandalone)
            root.manager.returnToEmbedded(root.deviceId)
        else
            root.manager.openStandalone(root.deviceId)
        close()
    }

    contentItem: ColumnLayout {
        spacing: 2

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 9
            Layout.rightMargin: 9
            Layout.topMargin: 3
            Layout.bottomMargin: 6
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: root.deviceName
                color: Theme.text
                elide: Text.ElideRight
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Text {
                text: root.deviceType.toUpperCase() + "  ·  " + root.deviceStatus
                color: root.deviceStatus === "Running" ? Theme.success : Theme.textMuted
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 0.7
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 5
            color: toggleMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.deviceLocked
                      ? "Android runtime locked"
                      : (root.deviceStatus === "Running" ? "Stop Device" : "Start Device")
                color: root.deviceLocked ? Theme.textFaint : Theme.text
                font.pixelSize: 12
            }

            MouseArea {
                id: toggleMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !root.deviceLocked
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.toggleDevice()
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 9
            Layout.topMargin: 7
            Layout.bottomMargin: 2
            text: "DEVICE ACTIONS"
            color: Theme.textFaint
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 1.0
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 5
            color: reloadMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Reload Device"
                color: Theme.text
                font.pixelSize: 12
            }

            MouseArea {
                id: reloadMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.reloadDevice(false)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 5
            color: hardReloadMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.deviceType === "android" ? "Restart Android runtime" : "Hard Reload"
                color: Theme.text
                font.pixelSize: 12
            }

            MouseArea {
                id: hardReloadMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.reloadDevice(true)
            }
        }

        Rectangle {
            visible: root.isWebDevice
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 5
            color: standaloneMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.isStandalone ? "Return to Hesh" : "Open in Window"
                color: Theme.text
                font.pixelSize: 12
            }

            MouseArea {
                id: standaloneMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleStandalone()
            }
        }

        Rectangle {
            Layout.topMargin: 5
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 5
            color: removeMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Remove Device"
                color: Theme.error
                font.pixelSize: 12
            }

            MouseArea {
                id: removeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.removeDevice()
            }
        }
    }
}
