import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hesh 1.0

Item {
    id: root

    property var device
    property var manager
    readonly property bool compact: width < 760
    property bool showDevTools: false

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            id: stage
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                color: Theme.window

                Text {
                    anchors.centerIn: parent
                    visible: !root.device
                    text: "Select a device to begin"
                    color: Theme.textFaint
                    font.pixelSize: 13
                }
            }

            DeviceFrame {
                id: deviceFrame
                anchors.centerIn: parent
                device: root.device
                availableWidth: stage.width
                availableHeight: stage.height
                visible: root.device !== null
                showDevTools: root.showDevTools

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

                TextField {
                    id: urlField
                    Layout.fillWidth: true
                    text: root.device ? root.device.url : ""
                    color: Theme.textMuted
                    font.pixelSize: 11
                    selectByMouse: true
                    placeholderText: "Enter a URL"
                    placeholderTextColor: Theme.textFaint
                    background: Rectangle {
                        color: Theme.input
                        border.width: urlField.activeFocus ? 1 : 0
                        border.color: Theme.accentStrong
                        radius: Theme.radiusSmall
                    }
                    leftPadding: 10
                    rightPadding: 10
                    onAccepted: {
                        if (root.device && text.trim().length > 0) root.device.url = text.trim()
                    }
                }

                AppButton {
                    compact: true
                    text: "Go"
                    onClicked: {
                        if (root.device && urlField.text.trim().length > 0) {
                            root.device.url = urlField.text.trim()
                            urlField.focus = false
                        }
                    }
                }

                AppButton {
                    compact: true
                    text: root.showDevTools ? "Hide DevTools" : "DevTools"
                    secondary: true
                    onClicked: root.showDevTools = !root.showDevTools
                }

                Text {
                    visible: !root.compact
                    text: root.device ? root.device.viewportWidth + " × " + root.device.viewportHeight : ""
                    color: Theme.text
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }

                Text {
                    visible: !root.compact
                    text: root.device ? "DPR " + Number(root.device.devicePixelRatio).toFixed(2) : ""
                    color: Theme.textMuted
                    font.pixelSize: 11
                }

                Text {
                    visible: !root.compact
                    text: deviceFrame.presentationMode
                    color: Theme.textMuted
                    font.pixelSize: 11
                }

                Text {
                    visible: !root.compact
                    text: deviceFrame.presentationPercent + "%"
                    color: Theme.accent
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
