import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hesh 1.0

Popup {
    id: root

    property var manager
    property int step: 0
    property string selectedType: ""

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    anchors.centerIn: Overlay.overlay
    width: 560
    height: step === 0 ? 420 : 530
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
        profileCombo.currentIndex = 0
    }

    onOpened: reset()
    onClosed: reset()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 0

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: root.step === 0 ? "Create Device" : "Create Web Device"
                    color: Theme.text
                    font.pixelSize: 19
                    font.weight: Font.Medium
                }

                Text {
                    text: root.step === 0 ? "Choose a runtime for your next test surface." : "Set the viewport and starting URL."
                    color: Theme.textMuted
                    font.pixelSize: 12
                }
            }

            IconButton {
                iconText: "×"
                tooltip: "Close"
                onClicked: root.close()
            }
        }

        Item { Layout.preferredHeight: 26 }

        ColumnLayout {
            visible: root.step === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Text {
                text: "What are you testing?"
                color: Theme.textMuted
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.6
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusSmall
                    color: webMouse.containsMouse ? Theme.accentSoft : Theme.panelRaised
                    border.width: webMouse.containsMouse ? 1 : 0
                    border.color: Theme.accentStrong

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 34
                        spacing: 11

                        Text {
                            text: "◇"
                            color: Theme.accent
                            font.pixelSize: 27
                        }

                        Text {
                            text: "Web Device"
                            color: Theme.text
                            font.pixelSize: 15
                            font.weight: Font.Medium
                        }

                        Text {
                            text: "Lightweight web\nemulation"
                            color: Theme.textMuted
                            lineHeight: 1.25
                            font.pixelSize: 12
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
                    color: Theme.panelRaised
                    border.width: 1
                    border.color: Theme.border

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 34
                        spacing: 11

                        Text {
                            text: "▣"
                            color: Theme.textFaint
                            font.pixelSize: 23
                        }

                        Text {
                            text: "Android Device"
                            color: Theme.textMuted
                            font.pixelSize: 15
                            font.weight: Font.Medium
                        }

                        Text {
                            text: "Real Android using\nhardware virtualization"
                            color: Theme.textFaint
                            lineHeight: 1.25
                            font.pixelSize: 12
                        }

                        Rectangle {
                            width: 96
                            height: 24
                            radius: 12
                            color: Theme.input
                            border.width: 1
                            border.color: Theme.border

                            Text {
                                anchors.centerIn: parent
                                text: "COMING LATER"
                                color: Theme.textFaint
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.7
                            }
                        }
                    }
                }
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
                    text: profileCombo.currentIndex >= 0 && root.manager
                          ? root.manager.availableProfiles[profileCombo.currentIndex].userAgent.split(" Chrome")[0]
                          : ""
                    color: Theme.textFaint
                    elide: Text.ElideRight
                    font.pixelSize: 10
                }
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
                        root.manager.createWebDevice(nameField.text, profileCombo.currentText, urlField.text)
                    }
                    root.close()
                }
            }
        }
    }
}
