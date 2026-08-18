import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hesh 1.0

Popup {
    id: root

    property var manager
    property int step: 0
    property string selectedType: ""
    property string errorMessage: ""
    readonly property bool androidFeatureEnabled: !!root.manager
                                                  && !!root.manager.androidFeatureEnabled

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    anchors.centerIn: Overlay.overlay
    width: Overlay.overlay ? Math.min(420, Overlay.overlay.width - 32) : 420
    height: step === 0 ? 300 : 500
    padding: 0

    Overlay.modal: Rectangle { color: "#99080a0e" }

    background: Rectangle {
        radius: Theme.radiusMedium
        color: Theme.panel
        border.width: 1
        border.color: Theme.borderStrong
    }

    function reset() {
        step = 0
        selectedType = ""
        nameField.text = "Pixel 7 Development"
        urlField.text = "http://localhost:3000"
        avdField.text = ""
        serialField.text = "emulator-5554"
        profileCombo.currentIndex = 0
        errorMessage = ""
    }

    onOpened: reset()
    onClosed: reset()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                text: root.step === 0
                      ? "Create Device"
                      : (root.selectedType === "android" ? "Create Android Device" : "Create Web Device")
                color: Theme.text
                font.pixelSize: 17
                font.weight: Font.Medium
            }

            Text {
                text: root.step === 0
                      ? "Choose a runtime for your next test surface."
                      : (root.selectedType === "android"
                         ? "Choose an AVD and Android runtime settings."
                         : "Set the viewport and starting URL.")
                color: Theme.textMuted
                font.pixelSize: 11
            }
        }

        Item { Layout.preferredHeight: 14 }

        ColumnLayout {
            visible: root.step === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Text {
                text: "What are you testing?"
                color: Theme.textMuted
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.6
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 112
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusSmall
                    color: webMouse.containsMouse ? Theme.accentSoft : Theme.panelRaised
                    border.width: 1
                    border.color: Theme.accentStrong

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 9
                            color: Theme.input
                            border.width: 1
                            border.color: Theme.border

                            Image {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                source: "qrc:/qt/qml/Hesh/assets/icons/web-device.svg"
                                sourceSize.width: 48
                                sourceSize.height: 48
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: "Web Device"
                                color: Theme.text
                                font.pixelSize: 14
                                font.weight: Font.Medium
                            }

                            Text {
                                text: "Browser-based runtime"
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                font.pixelSize: 11
                            }
                        }
                    }

                    MouseArea {
                        id: webMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedType = "web"
                            root.step = 1
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusSmall
                    opacity: root.androidFeatureEnabled ? 1.0 : 0.58
                    color: root.androidFeatureEnabled && androidMouse.containsMouse
                           ? Theme.accentSoft : Theme.panelRaised
                    border.width: root.selectedType === "android" ? 1 : 1
                    border.color: root.androidFeatureEnabled && root.selectedType === "android"
                                  ? Theme.accentStrong : Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 9
                            color: Theme.input
                            border.width: 1
                            border.color: Theme.border

                            Image {
                                anchors.centerIn: parent
                                width: 22
                                height: 25
                                source: "qrc:/qt/qml/Hesh/assets/icons/android-device.svg"
                                sourceSize.width: 24
                                sourceSize.height: 24
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: "Android Device"
                                color: Theme.textMuted
                                font.pixelSize: 14
                                font.weight: Font.Medium
                            }

                            Text {
                                text: root.androidFeatureEnabled
                                      ? "Native runtime"
                                      : "Locked — resource limits"
                                color: root.androidFeatureEnabled ? Theme.textFaint : Theme.warning
                                wrapMode: Text.WordWrap
                                font.pixelSize: 11
                            }

                            Rectangle {
                                Layout.preferredWidth: 94
                                Layout.preferredHeight: 22
                                radius: 11
                                color: Theme.input
                                border.width: 1
                                border.color: Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: root.androidFeatureEnabled ? "AVAILABLE" : "LOCKED"
                                    color: root.androidFeatureEnabled ? Theme.accent : Theme.warning
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.6
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: androidMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.androidFeatureEnabled
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            root.selectedType = "android"
                            root.step = 1
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !root.androidFeatureEnabled
                text: "Android runtime is temporarily locked to protect system resources."
                color: Theme.textFaint
                wrapMode: Text.WordWrap
                font.pixelSize: 10
            }
        }

        ColumnLayout {
            visible: root.step === 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            Text {
                text: "Name"
                color: Theme.textMuted
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            TextField {
                id: nameField
                Layout.fillWidth: true
                implicitHeight: 38
                color: Theme.text
                font.pixelSize: 12
                selectByMouse: true
                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.input
                    border.width: 1
                    border.color: parent.activeFocus ? Theme.accentStrong : Theme.border
                }
                leftPadding: 12
                rightPadding: 12
            }

            Text {
                visible: root.selectedType === "web" && root.errorMessage.length > 0
                text: root.errorMessage
                color: Theme.error
                wrapMode: Text.WordWrap
                font.pixelSize: 10
            }

            Text {
                text: "Device profile"
                color: Theme.textMuted
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            ComboBox {
                id: profileCombo
                Layout.fillWidth: true
                implicitHeight: 38
                model: root.manager ? root.manager.availableProfiles : []
                textRole: "name"
                valueRole: "name"
                leftPadding: 12
                rightPadding: 32
                contentItem: Text {
                    text: profileCombo.displayText
                    color: Theme.text
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 12
                }
                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.input
                    border.width: 1
                    border.color: profileCombo.activeFocus ? Theme.accentStrong : Theme.border
                }
                popup: Popup {
                    y: profileCombo.height + 4
                    width: profileCombo.width
                    padding: 4
                    contentItem: ListView {
                        implicitHeight: Math.min(contentHeight, 250)
                        model: profileCombo.popup.visible ? profileCombo.delegateModel : null
                        clip: true
                    }
                    background: Rectangle {
                        radius: Theme.radiusSmall
                        color: Theme.panelRaised
                        border.width: 1
                        border.color: Theme.borderStrong
                    }
                }
            }

            Text {
                visible: root.selectedType === "web"
                text: "URL"
                color: Theme.textMuted
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            TextField {
                id: urlField
                visible: root.selectedType === "web"
                Layout.fillWidth: true
                implicitHeight: 38
                color: Theme.text
                font.pixelSize: 12
                selectByMouse: true
                inputMethodHints: Qt.ImhUrlCharactersOnly
                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.input
                    border.width: 1
                    border.color: parent.activeFocus ? Theme.accentStrong : Theme.border
                }
                leftPadding: 12
                rightPadding: 12
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                Text {
                    text: "Viewport"
                    color: Theme.textMuted
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Text {
                    text: profileCombo.currentIndex >= 0 && root.manager
                          ? root.manager.availableProfiles[profileCombo.currentIndex].width + " × "
                            + root.manager.availableProfiles[profileCombo.currentIndex].height
                          : ""
                    color: Theme.text
                    font.pixelSize: 11
                }

                Item { Layout.fillWidth: true }

                Text {
                    Layout.fillWidth: true
                    text: profileCombo.currentIndex >= 0 && root.manager
                          ? root.manager.availableProfiles[profileCombo.currentIndex].userAgent.split(" Chrome")[0]
                          : ""
                    color: Theme.textFaint
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: 10
                }
            }

            Text {
                visible: root.selectedType === "android"
                text: "Android Virtual Device (AVD)"
                color: Theme.textMuted
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            TextField {
                id: avdField
                visible: root.selectedType === "android"
                Layout.fillWidth: true
                implicitHeight: 38
                color: Theme.text
                placeholderText: "e.g. Pixel_7_API_35"
                font.pixelSize: 12
                selectByMouse: true
                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.input
                    border.width: 1
                    border.color: parent.activeFocus ? Theme.accentStrong : Theme.border
                }
                leftPadding: 12
                rightPadding: 12
            }

            Text {
                visible: root.selectedType === "android"
                text: "ADB serial"
                color: Theme.textMuted
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            TextField {
                id: serialField
                visible: root.selectedType === "android"
                Layout.fillWidth: true
                implicitHeight: 38
                color: Theme.text
                placeholderText: "emulator-5554"
                font.pixelSize: 12
                selectByMouse: true
                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.input
                    border.width: 1
                    border.color: parent.activeFocus ? Theme.accentStrong : Theme.border
                }
                leftPadding: 12
                rightPadding: 12
            }
        }

        Item { Layout.preferredHeight: 24 }

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            Item { Layout.fillWidth: true }

            AppButton {
                text: "Cancel"
                secondary: true
                compact: true
                onClicked: root.close()
            }

            AppButton {
                visible: root.step === 1
                text: "Create Device"
                compact: true
                onClicked: {
                    if (root.manager) {
                        let created = null
                        if (root.selectedType === "android") {
                            created = root.manager.createAndroidDevice(nameField.text,
                                                                       profileCombo.currentText,
                                                                       avdField.text,
                                                                       serialField.text)
                        } else {
                            created = root.manager.createWebDevice(nameField.text,
                                                                   profileCombo.currentText,
                                                                   urlField.text)
                        }
                        if (!created) {
                            root.errorMessage = root.selectedType === "web"
                                ? "Enter a valid browser URL."
                                : "The Android device could not be created."
                            return
                        }
                    }
                    root.close()
                }
            }
        }
    }
}
