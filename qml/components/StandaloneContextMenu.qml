import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hesh 1.0

pragma ComponentBehavior: Bound

Popup {
    id: root

    property var hostWindow
    property var device
    property var frame

    signal returnToHeshRequested()
    signal rotateRequested()
    signal fitRequested()
    signal scaleRequested(real scale)
    signal devToolsRequested()
    signal closeRequested()

    parent: root.hostWindow ? root.hostWindow.contentItem : null
    width: 214
    padding: 7
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    function openAt(pointX, pointY) {
        x = Math.max(8, Math.min(pointX, parent.width - width - 8))
        y = Math.max(8, Math.min(pointY, parent.height - height - 8))
        open()
    }

    background: Rectangle {
        color: Theme.panelRaised
        border.width: 1
        border.color: Theme.borderStrong
        radius: Theme.radiusSmall
    }

    contentItem: ColumnLayout {
        spacing: 2

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 3
            Layout.bottomMargin: 3
            text: root.device ? root.device.name : "Device"
            color: Theme.text
            elide: Text.ElideRight
            font.pixelSize: 11
            font.weight: Font.Medium
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            text: root.device
                  ? root.device.orientation + "  ·  " + root.device.logicalViewportWidth
                    + " × " + root.device.logicalViewportHeight + "  ·  "
                    + (root.frame ? root.frame.presentationPercent : 100) + "%"
                  : ""
            color: Theme.textMuted
            font.pixelSize: 10
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.topMargin: 4
            Layout.bottomMargin: 3
            color: Theme.border
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 4
            color: returnMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: "Return to Hesh"
                color: Theme.text
                font.pixelSize: 11
            }

            MouseArea {
                id: returnMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.close()
                    root.returnToHeshRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 4
            color: rotateMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: "Rotate device"
                color: Theme.text
                font.pixelSize: 11
            }

            MouseArea {
                id: rotateMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.close()
                    root.rotateRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 4
            color: fitMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: "Fit to desktop"
                color: Theme.text
                font.pixelSize: 11
            }

            MouseArea {
                id: fitMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.close()
                    root.fitRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.topMargin: 3
            Layout.bottomMargin: 3
            color: Theme.border
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: [0.25, 0.5, 0.75, 1.0, 1.25]

                delegate: Rectangle {
                    required property real modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: 4
                    color: scaleMouse.containsMouse ? Theme.panelSoft : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: Math.round(parent.modelData * 100) + "%"
                        color: Theme.textMuted
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: scaleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.close()
                            root.scaleRequested(parent.modelData)
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 4
            color: devToolsMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: root.frame && root.frame.devToolsVisible ? "Hide DevTools" : "Open DevTools"
                color: Theme.text
                font.pixelSize: 11
            }

            MouseArea {
                id: devToolsMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.close()
                    root.devToolsRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 4
            color: closeMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: "Close window"
                color: Theme.error
                font.pixelSize: 11
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.close()
                    root.closeRequested()
                }
            }
        }
    }
}
