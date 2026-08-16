import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hesh 1.0

Item {
    id: root

    property var device
    property var manager
    property real availableWidth: 620
    property real availableHeight: 560
    readonly property bool isLoading: root.device && root.device.status === "Starting"
    readonly property bool featureLocked: root.manager && !root.manager.androidFeatureEnabled
    readonly property bool pageLoaded: root.device && root.device.booted
    readonly property bool canGoBack: false
    readonly property bool canGoForward: false
    readonly property string presentationMode: "Android"
    readonly property int presentationPercent: 100

    width: Math.min(root.availableWidth - 40, 560)
    height: Math.min(root.availableHeight - 40, 430)

    function setScale(scale) {}
    function useFit() {}
    function goBack() {}
    function goForward() {}
    function reloadOrStop() {
        if (!root.device || !root.manager || root.featureLocked)
            return
        if (root.device.status === "Running")
            root.manager.stopDevice(root.device.id)
        else
            root.manager.startDevice(root.device.id)
    }
    function navigate() {}
    function zoomIn() {}
    function zoomOut() {}

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMedium
        color: Theme.panelRaised
        border.width: 1
        border.color: Theme.borderStrong

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 14

            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 52
                Layout.preferredHeight: 52
                source: "qrc:/qt/qml/Hesh/assets/icons/android-device.svg"
                sourceSize.width: 64
                sourceSize.height: 64
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Text {
                Layout.fillWidth: true
                text: root.device ? root.device.name : "Android Device"
                horizontalAlignment: Text.AlignHCenter
                color: Theme.text
                font.pixelSize: 17
                font.weight: Font.Medium
            }

            Text {
                Layout.fillWidth: true
                text: root.featureLocked
                      ? "LOCKED  ·  emulator disabled to protect system resources"
                      : (root.device
                         ? root.device.runtimeState + "  ·  " + root.device.avdName
                           + "  ·  " + root.device.adbSerial
                         : "")
                horizontalAlignment: Text.AlignHCenter
                color: root.featureLocked
                       ? Theme.warning
                       : (root.device && root.device.status === "Error" ? Theme.error : Theme.textMuted)
                elide: Text.ElideMiddle
                font.pixelSize: 11
            }

            Text {
                Layout.fillWidth: true
                visible: root.device && root.device.errorMessage.length > 0
                text: root.device ? root.device.errorMessage : ""
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Theme.error
                font.pixelSize: 11
            }

            Text {
                Layout.fillWidth: true
                visible: root.featureLocked || (root.device && root.device.status !== "Error")
                text: root.featureLocked
                      ? "This resource-intensive feature is locked in this build. Re-enable HESH_ENABLE_ANDROID only on a machine with enough memory."
                      : (root.device && root.device.runtime.scrcpyAvailable
                         ? "Interactive display is provided by scrcpy."
                         : "The Android emulator window provides the display. Install scrcpy to mirror it here.")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Theme.textMuted
                font.pixelSize: 11
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                AppButton {
                    text: "Open Display"
                    compact: true
                    enabled: root.device && root.device.booted && !root.featureLocked
                    onClicked: if (root.device) root.device.openDisplay()
                }

                AppButton {
                    text: root.device && root.device.status === "Running" ? "Stop" : "Start"
                    secondary: true
                    compact: true
                    enabled: root.device !== null && !root.featureLocked
                    onClicked: {
                        if (!root.device)
                            return
                        if (root.device.status === "Running" || root.device.status === "Starting")
                            root.manager.stopDevice(root.device.id)
                        else
                            root.manager.startDevice(root.device.id)
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                AppButton {
                    text: "Back"
                    secondary: true
                    compact: true
                    enabled: root.device && root.device.booted && !root.featureLocked
                    onClicked: if (root.device) root.device.sendBack()
                }

                AppButton {
                    text: "Home"
                    secondary: true
                    compact: true
                    enabled: root.device && root.device.booted && !root.featureLocked
                    onClicked: if (root.device) root.device.sendHome()
                }

                AppButton {
                    text: "Recents"
                    secondary: true
                    compact: true
                    enabled: root.device && root.device.booted && !root.featureLocked
                    onClicked: if (root.device) root.device.sendRecents()
                }

                AppButton {
                    text: "Rotate"
                    secondary: true
                    compact: true
                    enabled: root.device && root.device.booted && !root.featureLocked
                    onClicked: if (root.device) root.device.rotateDevice()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                TextField {
                    id: apkPathField
                    Layout.fillWidth: true
                    implicitHeight: 32
                    enabled: !root.featureLocked
                    placeholderText: "APK path (optional)"
                    color: Theme.text
                    font.pixelSize: 11
                    selectByMouse: true
                    background: Rectangle {
                        radius: Theme.radiusSmall
                        color: Theme.input
                        border.width: 1
                        border.color: parent.activeFocus ? Theme.accentStrong : Theme.border
                    }
                    leftPadding: 10
                    rightPadding: 10
                }

                AppButton {
                    text: "Install APK"
                    secondary: true
                    compact: true
                    enabled: root.device && root.device.booted && !root.featureLocked
                             && apkPathField.text.length > 0
                    onClicked: if (root.device) root.device.installApk(apkPathField.text)
                }
            }
        }
    }
}
