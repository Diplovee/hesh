import QtQuick
import QtQuick.Layouts
import Hesh 1.0

pragma ComponentBehavior: Bound

Rectangle {
    id: root

    property var manager
    signal addDeviceRequested()
    signal editDeviceRequested(string deviceId)
    signal duplicateDeviceRequested(string deviceId)
    signal removeDeviceRequested(string deviceId)
    color: Theme.panel
    border.width: 1
    border.color: Theme.border

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 26
        anchors.bottomMargin: 14
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 22
            Layout.rightMargin: 20

            Text {
                text: "DEVICES"
                color: Theme.textMuted
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 1.4
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.manager ? root.manager.deviceCount : 0
                color: Theme.textFaint
                font.pixelSize: 11
            }
        }

        Item { Layout.preferredHeight: 16 }

        ListView {
            id: deviceList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.manager ? root.manager.devices : null

            delegate: DeviceListItem {
                manager: root.manager
                selected: root.manager && root.manager.selectedDevice
                          && root.manager.selectedDevice.id === deviceId
                deviceType: deviceType
                devicePresentationState: devicePresentationState
                deviceRuntimeState: deviceRuntimeState
                onActivated: if (root.manager) root.manager.selectDevice(deviceId)
                onEditRequested: root.editDeviceRequested(deviceId)
                onDuplicateRequested: root.duplicateDeviceRequested(deviceId)
                onRemoveRequested: root.removeDeviceRequested(deviceId)
            }

            Text {
                anchors.centerIn: parent
                visible: deviceList.count === 0
                text: "Your devices will appear here"
                color: Theme.textFaint
                font.pixelSize: 11
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.preferredHeight: 1
            color: Theme.border
        }

        Item { Layout.preferredHeight: 12 }

        AppButton {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            text: "+  Add Device"
            secondary: true
            compact: true
            onClicked: root.addDeviceRequested()
        }
    }
}
