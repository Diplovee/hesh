import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hesh 1.0

Popup {
    id: root

    property var manager
    property var device
    property bool duplicateMode: false
    property bool renameOnly: false
    property string errorMessage: ""

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    anchors.centerIn: Overlay.overlay
    width: Overlay.overlay ? Math.min(460, Overlay.overlay.width - 32) : 460
    height: root.duplicateMode || root.renameOnly ? 250 : 585
    padding: 0

    Overlay.modal: Rectangle { color: "#99080a0e" }

    background: Rectangle {
        radius: Theme.radiusMedium
        color: Theme.panel
        border.width: 1
        border.color: Theme.borderStrong
    }

    function openFor(target, duplicate) {
        root.device = target
        root.duplicateMode = duplicate
        root.renameOnly = !duplicate && target && target.type !== "web"
        root.errorMessage = ""
        open()
    }

    function populate() {
        if (!root.device)
            return
        nameField.text = root.device.name + (root.duplicateMode ? " Copy" : "")
        var profileIndex = 0
        for (var index = 0; index < profileCombo.model.length; ++index) {
            if (profileCombo.model[index].name === root.device.profileName) {
                profileIndex = index
                break
            }
        }
        profileCombo.currentIndex = profileIndex
        urlField.text = root.device.url
        orientationCombo.currentIndex = root.device.orientation === "Landscape" ? 1 : 0
        userAgentField.text = root.device.userAgent
    }

    onOpened: populate()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 0

        Text {
            text: root.duplicateMode ? "Duplicate Device"
                  : root.renameOnly ? "Rename Device" : "Edit Web Device"
            color: Theme.text
            font.pixelSize: 17
            font.weight: Font.Medium
        }

        Text {
            Layout.topMargin: 3
            text: root.duplicateMode
                  ? "Create an isolated browser profile with a new name."
                  : root.renameOnly ? "Choose a new name for this device."
                                    : "Update this device and save the changes immediately."
            color: Theme.textMuted
            font.pixelSize: 11
        }

        Item { Layout.preferredHeight: 16 }

        Text {
            text: "Name"
            color: Theme.textMuted
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        TextField {
            id: nameField
            Layout.fillWidth: true
            Layout.topMargin: 6
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

        ColumnLayout {
            visible: !root.duplicateMode && !root.renameOnly
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 14
            spacing: 10

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
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Text {
                        text: "URL"
                        color: Theme.textMuted
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    TextField {
                        id: urlField
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
                }

                ColumnLayout {
                    Layout.preferredWidth: 132
                    spacing: 5

                    Text {
                        text: "Orientation"
                        color: Theme.textMuted
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    ComboBox {
                        id: orientationCombo
                        Layout.fillWidth: true
                        implicitHeight: 38
                        model: ["Portrait", "Landscape"]
                        leftPadding: 10
                        rightPadding: 26
                        contentItem: Text {
                            text: orientationCombo.displayText
                            color: Theme.text
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 12
                        }
                        background: Rectangle {
                            radius: Theme.radiusSmall
                            color: Theme.input
                            border.width: 1
                            border.color: orientationCombo.activeFocus ? Theme.accentStrong : Theme.border
                        }
                    }
                }
            }

            Text {
                text: "User agent"
                color: Theme.textMuted
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            TextField {
                id: userAgentField
                Layout.fillWidth: true
                implicitHeight: 38
                color: Theme.text
                font.pixelSize: 11
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
                Layout.fillWidth: true
                text: root.errorMessage
                visible: text.length > 0
                color: Theme.error
                wrapMode: Text.WordWrap
                font.pixelSize: 10
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            Text {
                Layout.fillWidth: true
                text: root.duplicateMode && root.device ? "Profile: " + root.device.id : ""
                color: Theme.textFaint
                elide: Text.ElideMiddle
                font.pixelSize: 9
            }

            AppButton {
                text: "Cancel"
                secondary: true
                compact: true
                onClicked: root.close()
            }

            AppButton {
                text: root.duplicateMode ? "Duplicate"
                      : root.renameOnly ? "Rename" : "Save Changes"
                compact: true
                onClicked: {
                    if (!root.manager || !root.device)
                        return
                    const success = root.duplicateMode
                        ? !!root.manager.duplicateWebDevice(root.device.id, nameField.text)
                        : root.renameOnly
                          ? root.manager.renameDevice(root.device.id, nameField.text)
                          : root.manager.editWebDevice(root.device.id,
                                                     nameField.text,
                                                     profileCombo.currentText,
                                                     urlField.text,
                                                     orientationCombo.currentText,
                                                     userAgentField.text)
                    if (success) {
                        root.close()
                    } else {
                        root.errorMessage = root.duplicateMode || root.renameOnly
                            ? "A device name is required."
                            : "Enter a name and a valid browser URL."
                    }
                }
            }
        }
    }
}
