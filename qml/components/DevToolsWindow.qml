import QtQuick
import QtQuick.Window
import QtWebEngine
import Hesh 1.0

Window {
    id: root

    property var device
    property var inspectedView

    width: 980
    height: 720
    minimumWidth: 640
    minimumHeight: 420
    color: Theme.panel
    flags: Qt.Window
    title: device ? "Hesh DevTools — " + device.name : "Hesh DevTools"

    onClosing: {
        if (root.device)
            root.device.devToolsVisible = false
    }

    WebEngineView {
        anchors.fill: parent
        anchors.margins: 1
        backgroundColor: Theme.panel
        inspectedView: root.inspectedView
    }
}
