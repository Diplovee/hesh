import QtQuick
import QtQuick.Layouts
import Hesh 1.0

Item {
    id: root

    signal createRequested()

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 14

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            radius: 18
            color: Theme.accentSoft
            border.width: 1
            border.color: "#454a75"

            Text {
                anchors.centerIn: parent
                text: "◇"
                color: Theme.accent
                font.pixelSize: 30
                font.weight: Font.Light
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "No devices yet"
            color: Theme.text
            font.pixelSize: 20
            font.weight: Font.Medium
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Create a device to start testing\nyour application."
            color: Theme.textMuted
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.25
            font.pixelSize: 13
        }

        Item { Layout.preferredHeight: 2 }

        AppButton {
            Layout.alignment: Qt.AlignHCenter
            text: "+  Create Device"
            onClicked: root.createRequested()
        }
    }
}
