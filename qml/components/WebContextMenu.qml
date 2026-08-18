import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hesh 1.0

Popup {
    id: root

    property var device
    property var frame
    property var manager

    parent: Overlay.overlay
    width: 238
    padding: 7
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: Theme.panelRaised
        border.width: 1
        border.color: Theme.borderStrong
        radius: Theme.radiusSmall
    }

    function openAt(anchor, localX, localY) {
        const point = anchor.mapToItem(Overlay.overlay, localX, localY)
        x = Math.max(8, Math.min(point.x, Overlay.overlay.width - width - 8))
        y = Math.max(8, Math.min(point.y, Overlay.overlay.height - height - 8))
        open()
    }

    function closeAfter(action) {
        close()
        action()
    }

    function reload(hard) {
        if (!root.frame)
            return
        if (hard)
            root.frame.hardReload()
        else
            root.frame.reload()
    }

    contentItem: ColumnLayout {
        spacing: 2

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 9
            Layout.rightMargin: 9
            Layout.topMargin: 3
            Layout.bottomMargin: 6
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: root.device ? root.device.name : "Web device"
                color: Theme.text
                elide: Text.ElideRight
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Text {
                text: root.device
                      ? root.device.orientation + "  ·  "
                        + root.device.logicalViewportWidth + " × "
                        + root.device.logicalViewportHeight + "  ·  "
                        + (root.frame ? root.frame.presentationPercent : 100) + "%"
                      : ""
                color: Theme.textMuted
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
            Layout.preferredHeight: 32
            radius: 4
            color: backMouse.containsMouse ? Theme.panelSoft : "transparent"
            opacity: root.frame && root.frame.canGoBack ? 1 : 0.45

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: "Back"
                color: Theme.text
                font.pixelSize: 11
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                enabled: root.frame && root.frame.canGoBack
                hoverEnabled: true
                onClicked: root.closeAfter(function() { root.frame.goBack() })
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 4
            color: forwardMouse.containsMouse ? Theme.panelSoft : "transparent"
            opacity: root.frame && root.frame.canGoForward ? 1 : 0.45

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: "Forward"
                color: Theme.text
                font.pixelSize: 11
            }

            MouseArea {
                id: forwardMouse
                anchors.fill: parent
                enabled: root.frame && root.frame.canGoForward
                hoverEnabled: true
                onClicked: root.closeAfter(function() { root.frame.goForward() })
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 4
            color: reloadMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: "Reload"
                color: Theme.text
                font.pixelSize: 11
            }

            MouseArea {
                id: reloadMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.closeAfter(function() { root.reload(false) })
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 4
            color: hardReloadMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: "Hard reload"
                color: Theme.text
                font.pixelSize: 11
            }

            MouseArea {
                id: hardReloadMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.closeAfter(function() { root.reload(true) })
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.topMargin: 3
            Layout.bottomMargin: 3
            color: Theme.border
        }

        Rectangle {
            visible: !!root.manager && !!root.device && root.device.presentationState !== "Standalone"
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 4
            color: openMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: "Open in Window"
                color: Theme.text
                font.pixelSize: 11
            }

            MouseArea {
                id: openMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.closeAfter(function() {
                    root.manager.openStandalone(root.device.id)
                })
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
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
                onClicked: root.closeAfter(function() {
                    root.device.orientation = root.device.orientation === "Landscape" ? "Portrait" : "Landscape"
                })
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 4
            color: fitMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: "Fit to workspace"
                color: Theme.text
                font.pixelSize: 11
            }

            MouseArea {
                id: fitMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.closeAfter(function() { root.frame.useFit() })
            }
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
                        onClicked: root.closeAfter(function() { root.frame.setScale(parent.modelData) })
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 4
            color: devToolsMouse.containsMouse ? Theme.panelSoft : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: root.device && root.device.devToolsVisible ? "Hide DevTools" : "Open DevTools"
                color: Theme.text
                font.pixelSize: 11
            }

            MouseArea {
                id: devToolsMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.closeAfter(function() {
                    root.device.devToolsVisible = !root.device.devToolsVisible
                })
            }
        }
    }
}
