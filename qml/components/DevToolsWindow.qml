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

    function forceDarkTheme() {
        devToolsView.runJavaScript(
            "(function() {"
            + "  var root = document.documentElement;"
            + "  if (!root) return;"
            + "  root.classList.remove('theme-with-light-background');"
            + "  root.classList.add('theme-with-dark-background');"
            + "  root.style.colorScheme = 'dark';"
            + "  if (document.body) document.body.style.colorScheme = 'dark';"
            + "})();")
    }

    WebEngineView {
        id: devToolsView
        anchors.fill: parent
        anchors.margins: 1
        backgroundColor: Theme.panel
        inspectedView: root.inspectedView

        // Chromium DevTools uses this class for its dark design-token set.
        // The inspected page is a separate WebEngineView and is not changed.
        userScripts.collection: [{
            name: "hesh-devtools-dark-theme",
            injectionPoint: WebEngineScript.DocumentReady,
            worldId: WebEngineScript.MainWorld,
            runsOnSubFrames: false,
            sourceCode: "(function() {"
                         + "  var root = document.documentElement;"
                         + "  if (!root) return;"
                         + "  root.classList.remove('theme-with-light-background');"
                         + "  root.classList.add('theme-with-dark-background');"
                         + "  root.style.colorScheme = 'dark';"
                         + "  if (document.body) document.body.style.colorScheme = 'dark';"
                         + "})();"
        }]

        onLoadingChanged: function(loadRequest) {
            if (loadRequest.status === WebEngineView.LoadSucceededStatus)
                Qt.callLater(root.forceDarkTheme)
        }
    }
}
