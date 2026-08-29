import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hesh 1.0

// A compact, Hesh-styled menu for the standalone surface. It intentionally
// exposes browser navigation without allowing the page's native Chromium
// menu to replace the app's visual language.
Popup {
    id: root

    property var device: null
    property bool canGoBack: false
    property bool canGoForward: false

    signal reloadRequested()
    signal backRequested()
    signal forwardRequested()
    signal closeRequested()

    width: 252
    padding: 8
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: Theme.panelRaised
        border.width: 1
        border.color: Theme.borderStrong
        radius: Theme.radiusSmall
    }

    function openAt(localX, localY) {
        x = Math.max(8, Math.min(localX, parent.width - width - 8))
        y = Math.max(8, Math.min(localY, parent.height - height - 8))
        open()
    }

    function itemColor(mouse, enabled) {
        if (!enabled) return "transparent"
        return mouse.containsMouse ? Theme.panelSoft : "transparent"
    }

    contentItem: ColumnLayout {
        spacing: 3

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 3
            Layout.bottomMargin: 5
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: root.device ? root.device.name : "Web device"
                color: Theme.text
                elide: Text.ElideRight
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            Text {
                Layout.fillWidth: true
                text: root.device ? root.device.url : ""
                color: Theme.textFaint
                elide: Text.ElideMiddle
                font.pixelSize: 10
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 5
            color: root.itemColor(reloadMouse, true)

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Reload Preview"
                color: Theme.text
                font.pixelSize: 12
            }

            MouseArea {
                id: reloadMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.reloadRequested()
                    root.close()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 5
            color: root.itemColor(backMouse, root.canGoBack)
            opacity: root.canGoBack ? 1.0 : 0.45

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Back"
                color: Theme.text
                font.pixelSize: 12
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                enabled: root.canGoBack
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.backRequested()
                    root.close()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 5
            color: root.itemColor(forwardMouse, root.canGoForward)
            opacity: root.canGoForward ? 1.0 : 0.45

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Forward"
                color: Theme.text
                font.pixelSize: 12
            }

            MouseArea {
                id: forwardMouse
                anchors.fill: parent
                enabled: root.canGoForward
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.forwardRequested()
                    root.close()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 5
            color: closeMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Close Standalone Window"
                color: Theme.error
                font.pixelSize: 12
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.close()
                    root.closeRequested()
                }
            }
        }
    }
}
