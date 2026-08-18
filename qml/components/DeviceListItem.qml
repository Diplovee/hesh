import QtQuick
import QtQuick.Layouts
import Hesh 1.0

Item {
    id: root

    required property string deviceId
    required property string deviceName
    required property string deviceTypeLabel
    required property string deviceType
    required property string deviceStatus
    required property string devicePresentationState
    required property string deviceRuntimeState
    property var manager
    property bool selected: false
    signal activated()
    signal editRequested(string deviceId)
    signal duplicateRequested(string deviceId)
    signal removeRequested(string deviceId)

    implicitHeight: 76
    width: ListView.view ? ListView.view.width : 220

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        radius: Theme.radiusSmall
        color: root.selected ? Theme.accentSoft : (rowMouseArea.containsMouse ? Theme.panelRaised : "transparent")
        border.width: root.selected ? 1 : 0
        border.color: "#454a75"

        Rectangle {
            width: 3
            height: parent.height - 18
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            radius: 2
            color: root.selected ? Theme.accent : "transparent"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 14
            spacing: 9

            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 6
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: 4
                    color: root.deviceRuntimeState === "Error" ? Theme.error
                           : root.deviceRuntimeState === "Loading" ? Theme.warning
                           : root.deviceStatus === "Running" ? Theme.success : Theme.textFaint
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: root.deviceName
                    color: Theme.text
                    elide: Text.ElideRight
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                RowLayout {
                    spacing: 7

                    Text {
                        text: root.deviceTypeLabel
                        color: root.selected ? Theme.accent : Theme.textMuted
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.devicePresentationState === "Standalone" ? "Standalone"
                              : (root.deviceRuntimeState === "Loading" || root.deviceRuntimeState === "Error"
                                 ? root.deviceRuntimeState : root.deviceStatus)
                        color: root.deviceRuntimeState === "Error" ? Theme.error
                               : root.deviceRuntimeState === "Loading" ? Theme.warning : Theme.textMuted
                        elide: Text.ElideMiddle
                        font.pixelSize: 11
                    }
                }
            }

        }

        MouseArea {
            id: rowMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton)
                    deviceMenu.openAt(rowMouseArea, mouse.x, mouse.y)
                else
                    root.activated()
            }
        }
    }

    DeviceContextMenu {
        id: deviceMenu
        manager: root.manager
        deviceId: root.deviceId
        deviceName: root.deviceName
        deviceType: root.deviceType
        deviceStatus: root.deviceStatus
        devicePresentationState: root.devicePresentationState
        onEditRequested: root.editRequested(root.deviceId)
        onDuplicateRequested: root.duplicateRequested(root.deviceId)
        onRemoveRequested: root.removeRequested(root.deviceId)
    }
}
