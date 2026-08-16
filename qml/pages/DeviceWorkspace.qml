import QtQuick
import QtQuick.Layouts
import Hesh 1.0

Item {
    id: root

    property var device
    property var manager

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            Layout.leftMargin: 30
            Layout.rightMargin: 28
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: root.device ? root.device.name : ""
                    color: Theme.text
                    font.pixelSize: 17
                    font.weight: Font.Medium
                }

                Text {
                    text: root.device ? root.device.typeLabel + " DEVICE  /  " + root.device.profileName : ""
                    color: Theme.textMuted
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.9
                }
            }

            IconButton {
                id: menuButton
                iconText: "⋯"
                tooltip: "Device actions"
                enabled: root.device !== null
                onClicked: deviceMenu.openFor(menuButton)
            }
        }

        DeviceContextMenu {
            id: deviceMenu
            manager: root.manager
            deviceId: root.device ? root.device.id : ""
            deviceName: root.device ? root.device.name : ""
            deviceStatus: root.device ? root.device.status : "Stopped"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        Item {
            id: stage
            Layout.fillWidth: true
            Layout.fillHeight: true

            DeviceFrame {
                id: deviceFrame
                anchors.centerIn: parent
                device: root.device
                availableWidth: stage.width
                availableHeight: stage.height
                visible: root.device !== null

                Behavior on presentationScale {
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: Theme.panel
            border.width: 1
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 30
                anchors.rightMargin: 28
                spacing: 18

                Text {
                    Layout.fillWidth: true
                    text: root.device ? root.device.url : ""
                    color: Theme.textMuted
                    elide: Text.ElideMiddle
                    font.pixelSize: 11
                }

                Text {
                    text: root.device ? root.device.viewportWidth + " × " + root.device.viewportHeight : ""
                    color: Theme.text
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }

                Text {
                    text: root.device ? "DPR " + Number(root.device.devicePixelRatio).toFixed(2) : ""
                    color: Theme.textMuted
                    font.pixelSize: 11
                }

                Text {
                    text: deviceFrame.presentationMode
                    color: Theme.textMuted
                    font.pixelSize: 11
                }

                Text {
                    text: deviceFrame.presentationPercent + "%"
                    color: Theme.accent
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
