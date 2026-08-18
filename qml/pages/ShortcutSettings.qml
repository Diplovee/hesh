import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hesh 1.0

pragma ComponentBehavior: Bound

Item {
    id: root

    property var shortcutManager
    property string recordingActionId: ""
    signal closeRequested()

    focus: root.recordingActionId.length > 0

    function beginRecording(actionId) {
        root.recordingActionId = actionId
        root.forceActiveFocus()
    }

    function stopRecording() {
        root.recordingActionId = ""
    }

    Keys.onPressed: function(event) {
        if (root.recordingActionId.length === 0)
            return

        if (event.key === Qt.Key_Escape) {
            root.stopRecording()
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Backspace) {
            root.shortcutManager.setShortcut(root.recordingActionId, "")
            root.stopRecording()
            event.accepted = true
            return
        }

        const sequence = root.shortcutManager.sequenceFromKeyEvent(event.key, event.modifiers)
        if (sequence.length === 0) {
            event.accepted = true
            return
        }
        if (root.shortcutManager.setShortcut(root.recordingActionId, sequence))
            root.stopRecording()
        event.accepted = true
    }

    Rectangle {
        anchors.fill: parent
        color: "#99000000"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
        }
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 1360)
        height: Math.min(parent.height - 48, 900)
        color: Theme.window
        radius: 14
        border.width: 1
        border.color: Theme.borderStrong

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 18

                ColumnLayout {
                    spacing: 4

                    Text {
                        text: "KEYBOARD SHORTCUTS"
                        color: Theme.text
                        font.pixelSize: 20
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "Customize Hesh actions. Record a shortcut or leave an action unassigned."
                        color: Theme.textMuted
                        font.pixelSize: 11
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }

                Text {
                    text: actionList.count + " actions"
                    color: Theme.textFaint
                    font.pixelSize: 11
                }

                AppButton {
                    text: "Reset all"
                    compact: true
                    secondary: true
                    Layout.preferredWidth: 108
                    onClicked: root.shortcutManager.resetAllShortcuts()
                }

                IconButton {
                    iconText: "×"
                    tooltip: "Close settings"
                    onClicked: root.closeRequested()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.border
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 14
                Layout.rightMargin: 12
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: "ACTION"
                    color: Theme.textFaint
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                }

                Text {
                    Layout.preferredWidth: 154
                    text: "CURRENT KEY"
                    color: Theme.textFaint
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                }

                Item { Layout.preferredWidth: 104 }
                Item { Layout.preferredWidth: 86 }
            }

            Text {
                Layout.fillWidth: true
                visible: !!root.shortcutManager
                         && root.shortcutManager.errorMessage.length > 0
                text: root.shortcutManager ? root.shortcutManager.errorMessage : ""
                color: Theme.error
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            ListView {
                id: actionList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 7
                model: root.shortcutManager
                cacheBuffer: 560
                reuseItems: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 4200
                maximumFlickVelocity: 5200

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 8
                }

                WheelHandler {
                    target: null
                    onWheel: function(event) {
                        const delta = event.angleDelta.y !== 0
                                      ? event.angleDelta.y : event.pixelDelta.y
                        if (delta === 0)
                            return
                        const maximum = Math.max(0, actionList.contentHeight - actionList.height)
                        actionList.contentY = Math.max(0, Math.min(maximum,
                                                                   actionList.contentY - delta * 0.72))
                        event.accepted = true
                    }
                }

                delegate: Rectangle {
                    id: actionRow
                    required property string actionId
                    required property string label
                    required property string category
                    required property string defaultSequence
                    required property string sequence

                    width: actionList.width - 12
                    height: 70
                    radius: Theme.radiusSmall
                    color: root.recordingActionId === actionId
                           ? Theme.accentSoft : Theme.panel
                    border.width: 1
                    border.color: root.recordingActionId === actionId
                                  ? Theme.accentStrong : Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: actionRow.label
                                color: Theme.text
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Text {
                                text: actionRow.category
                                color: Theme.textFaint
                                font.pixelSize: 10
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 154
                            Layout.minimumWidth: 154
                            Layout.preferredHeight: 32
                            radius: Theme.radiusSmall
                            color: Theme.input
                            border.width: 1
                            border.color: root.recordingActionId === actionId
                                          ? Theme.accentStrong : Theme.border

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                text: root.recordingActionId === actionId
                                      ? "Press keys…"
                                      : (actionRow.sequence.length > 0
                                         ? actionRow.sequence : "Unassigned")
                                color: root.recordingActionId === actionId
                                       ? Theme.accent : Theme.textMuted
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }

                        AppButton {
                            text: root.recordingActionId === actionId ? "Cancel" : "Record"
                            compact: true
                            secondary: true
                            Layout.preferredWidth: 104
                            onClicked: {
                                if (root.recordingActionId === actionId)
                                    root.stopRecording()
                                else
                                    root.beginRecording(actionId)
                            }
                        }

                        AppButton {
                            text: "Reset"
                            compact: true
                            secondary: true
                            Layout.preferredWidth: 86
                            enabled: actionRow.sequence !== actionRow.defaultSequence
                            onClicked: root.shortcutManager.resetShortcut(actionId)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    text: "Duplicate bindings are rejected. Backspace clears a binding; Escape cancels recording."
                    color: Theme.textFaint
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

                AppButton {
                    text: "Done"
                    compact: true
                    Layout.preferredWidth: 104
                    onClicked: root.closeRequested()
                }
            }
        }
    }
}
