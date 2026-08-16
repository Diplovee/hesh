import QtQuick
import Hesh 1.0

Item {
    id: root

    property string status: "Stopped"
    implicitWidth: badgeRow.implicitWidth
    implicitHeight: 18

    Row {
        id: badgeRow
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            anchors.verticalCenter: parent.verticalCenter
            color: root.status === "Running" ? Theme.success
                   : root.status === "Starting" ? Theme.warning
                   : root.status === "Error" ? Theme.error
                   : Theme.textFaint
        }

        Text {
            text: root.status
            color: Theme.textMuted
            font.pixelSize: 11
            font.weight: Font.Medium
        }
    }
}
