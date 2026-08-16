import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hesh 1.0

pragma ComponentBehavior: Bound

ApplicationWindow {
    id: window

    visible: true
    width: 1240
    height: 780
    minimumWidth: 900
    minimumHeight: 580
    color: Theme.window
    flags: Qt.Window | Qt.FramelessWindowHint
    title: "Hesh"

    property bool maximized: false
    function toggleMaximize() {
        if (maximized) {
            showNormal()
            maximized = false
        } else {
            showMaximized()
            maximized = true
        }
    }

    Component.onCompleted: {
        if (Qt.application.arguments.indexOf("--maximized") >= 0) {
            showMaximized()
            maximized = true
        }
    }

    Rectangle {
        id: shell
        anchors.fill: parent
        color: Theme.window
        border.width: 1
        border.color: Theme.borderStrong
        radius: 8
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: titlebar
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                color: Theme.panel
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 12
                    spacing: 14

                    Image {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        source: "qrc:/qt/qml/Hesh/assets/icons/hesh.png"
                        sourceSize.width: 64
                        sourceSize.height: 64
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Text {
                        text: "HESH"
                        color: Theme.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        font.letterSpacing: 2.0
                    }

                    Text {
                        text: "DEVICE DEVELOPMENT"
                        color: Theme.textFaint
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }

                    Item { Layout.fillWidth: true }

                    AppButton {
                        text: "+  New Device"
                        compact: true
                        onClicked: createDeviceDialog.open()
                    }

                    AppButton {
                        text: "Settings"
                        compact: true
                        secondary: true
                        enabled: false
                        ToolTip.visible: false
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 22
                        color: Theme.border
                    }

                    IconButton {
                        iconText: "—"
                        tooltip: "Minimize"
                        onClicked: window.showMinimized()
                    }

                    IconButton {
                        iconText: window.maximized ? "❐" : "□"
                        tooltip: window.maximized ? "Restore" : "Maximize"
                        onClicked: window.toggleMaximize()
                    }

                    IconButton {
                        iconText: "×"
                        tooltip: "Close"
                        onClicked: Qt.quit()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    acceptedButtons: Qt.LeftButton
                    onPressed: window.startSystemMove()
                    onDoubleClicked: window.toggleMaximize()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Sidebar {
                    id: sidebar
                    Layout.fillHeight: true
                    Layout.preferredWidth: 252
                    manager: deviceManager
                    onAddDeviceRequested: createDeviceDialog.open()
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.window

                    EmptyState {
                        anchors.fill: parent
                        visible: deviceManager.deviceCount === 0
                        onCreateRequested: createDeviceDialog.open()
                    }

                    DeviceWorkspace {
                        anchors.fill: parent
                        visible: deviceManager.deviceCount > 0
                        manager: deviceManager
                        device: deviceManager.selectedDevice
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                color: Theme.panel
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 18

                    Text {
                        text: deviceManager.deviceCount > 0 ? "Hesh  •  Web device ready" : "Hesh  •  Ready to create a device"
                        color: Theme.textFaint
                        font.pixelSize: 10
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Phase 1"
                        color: Theme.textFaint
                        font.pixelSize: 10
                    }

                    Text {
                        text: "DevTools  ↗"
                        color: Theme.textMuted
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }

    CreateDeviceDialog {
        id: createDeviceDialog
        manager: deviceManager
    }
}
