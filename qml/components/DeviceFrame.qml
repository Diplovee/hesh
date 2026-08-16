import QtQuick
import QtWebEngine
import Hesh 1.0

pragma ComponentBehavior: Bound

Item {
    id: root

    property var device
    property real availableWidth: 620
    property real availableHeight: 560
    property int bezel: 12
    property int screenRadius: 14
    property bool frameChromeVisible: true
    property string fitMode: "Fit"
    property real manualScale: 1.0
    property bool devToolsVisible: false
    property int devToolsWidth: 360

    readonly property real logicalWidth: root.device ? root.device.logicalViewportWidth : 0
    readonly property real logicalHeight: root.device ? root.device.logicalViewportHeight : 0
    readonly property real chromeInset: root.frameChromeVisible ? root.bezel : 0
    readonly property real frameWidth: root.logicalWidth + root.chromeInset * 2
    readonly property real frameHeight: root.logicalHeight + root.chromeInset * 2
    readonly property real fitAvailableWidth: Math.max(1, root.availableWidth
                                                        - (root.devToolsVisible ? root.devToolsWidth + 12 : 0)
                                                        - (root.frameChromeVisible ? 32 : 0))
    readonly property real fitAvailableHeight: Math.max(1,
                                                        root.availableHeight
                                                        - (root.frameChromeVisible ? 32 : 0))
    readonly property real fitScale: root.device
                                     ? Math.min(1.5,
                                                Math.max(0.1, root.fitAvailableWidth / root.frameWidth),
                                                Math.max(0.1, root.fitAvailableHeight / root.frameHeight))
                                     : 1.0
    readonly property real presentationScale: root.fitMode === "Fit" ? root.fitScale : root.manualScale
    readonly property int presentationPercent: Math.round(root.presentationScale * 100)
    readonly property string presentationMode: root.fitMode === "Fit" ? "Fit" : "Scale"
    readonly property bool isLoading: root.device ? root.device.loading : false
    readonly property bool pageLoaded: root.device ? root.device.runtimeState === "Loaded" : false
    readonly property bool canGoBack: webView.canGoBack
    readonly property bool canGoForward: webView.canGoForward

    width: root.device ? root.frameWidth * root.presentationScale
                       + (root.devToolsVisible ? root.devToolsWidth + 12 : 0) : 0
    height: root.device ? root.frameHeight * root.presentationScale : 0

    function setScale(scale) {
        root.manualScale = scale
        root.fitMode = "Manual"
    }

    function useFit() {
        root.fitMode = "Fit"
    }

    function navigate() {
        if (root.device && root.device.url.length > 0) {
            webView.url = root.device.url
        }
    }

    function goBack() {
        if (webView.canGoBack)
            webView.goBack()
    }

    function goForward() {
        if (webView.canGoForward)
            webView.goForward()
    }

    function reloadOrStop() {
        if (webView.loading)
            webView.stop()
        else
            webView.reload()
    }

    function retry() {
        root.navigate()
        webView.reload()
    }

    function zoomIn() {
        webView.zoomFactor = Math.min(3.0, webView.zoomFactor + 0.1)
    }

    function zoomOut() {
        webView.zoomFactor = Math.max(0.25, webView.zoomFactor - 0.1)
    }

    Rectangle {
        id: frame
        width: root.frameWidth
        height: root.frameHeight
        scale: root.presentationScale
        transformOrigin: Item.TopLeft
        radius: root.frameChromeVisible ? root.screenRadius : 0
        color: root.frameChromeVisible ? Theme.panelRaised : "#0d1014"
        border.width: root.frameChromeVisible ? 1 : 0
        border.color: root.frameChromeVisible ? Theme.borderStrong : "transparent"
        clip: true

        Text {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            height: root.bezel - 2
            verticalAlignment: Text.AlignVCenter
            visible: root.frameChromeVisible
            text: root.device ? root.device.profileName : ""
            color: Theme.textFaint
            font.pixelSize: 9
            font.weight: Font.Medium
        }

        Rectangle {
            id: contentSurface
            anchors.fill: parent
            anchors.margins: root.chromeInset
            radius: root.frameChromeVisible ? root.screenRadius : 0
            color: "#0d1014"
            clip: true

            WebEngineView {
                id: webView
                anchors.fill: parent
                url: root.device && root.device.status === "Running" ? root.device.url : "about:blank"
                profile: root.device ? root.device.browserProfile : null
                backgroundColor: "#0d1014"
                settings.fullScreenSupportEnabled: false
                settings.javascriptEnabled: true
                settings.localContentCanAccessRemoteUrls: true
                userScripts.collection: [{
                    name: "hesh-responsive-viewport",
                    injectionPoint: WebEngineScript.DocumentReady,
                    worldId: WebEngineScript.MainWorld,
                    runsOnSubFrames: false,
                    sourceCode: "(function() {\n"
                                 + "    if (!document.head) return;\n"
                                 + "    var viewport = document.querySelector('meta[name=\\\"viewport\\\"]');\n"
                                 + "    if (!viewport) {\n"
                                 + "        viewport = document.createElement('meta');\n"
                                 + "        viewport.name = 'viewport';\n"
                                 + "        document.head.appendChild(viewport);\n"
                                 + "    }\n"
                                 + "    var content = viewport.getAttribute('content') || '';\n"
                                 + "    var normalized = content.toLowerCase();\n"
                                 + "    if (normalized.indexOf('width') === -1)\n"
                                 + "        content = (content ? content + ', ' : '') + 'width=device-width';\n"
                                 + "    normalized = content.toLowerCase();\n"
                                 + "    if (normalized.indexOf('initial-scale') === -1)\n"
                                 + "        content += (content ? ', ' : '') + 'initial-scale=1';\n"
                                 + "    viewport.setAttribute('content', content);\n"
                                 + "})();"
                }]

                onLoadingChanged: function(loadRequest) {
                    if (!root.device)
                        return
                    if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                        root.device.setRuntimeError(loadRequest.errorString.length > 0
                                                    ? loadRequest.errorString
                                                    : "Navigation failed")
                    } else if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                        root.device.setRuntimeLoaded()
                    } else {
                        root.device.setLoading(true)
                    }
                }

                onUrlChanged: {
                    if (root.device && url.toString() !== root.device.url)
                        root.device.url = url.toString()
                }

                onCanGoBackChanged: {
                    if (root.device)
                        root.device.setNavigationState(canGoBack, canGoForward)
                }

                onCanGoForwardChanged: {
                    if (root.device)
                        root.device.setNavigationState(canGoBack, canGoForward)
                }

                onRenderProcessTerminated: function(terminationStatus, exitCode) {
                    if (root.device)
                        root.device.setRuntimeError("The WebEngine render process stopped (" + exitCode + ").")
                }
            }

            Rectangle {
                anchors.fill: parent
                z: 2
                visible: root.device && root.device.runtimeState === "Loading"
                color: "#0d1014"

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "LOADING"
                        color: Theme.accent
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.7
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.device ? root.device.url : ""
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                z: 3
                visible: root.device && root.device.runtimeState === "Error"
                color: "#0d1014"

                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 36, 300)
                    spacing: 10

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "COULDN'T REACH"
                        color: Theme.error
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.4
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: root.device ? root.device.url : ""
                        color: Theme.text
                        elide: Text.ElideMiddle
                        font.pixelSize: 12
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: root.device ? root.device.errorMessage : "Navigation failed"
                        color: Theme.textMuted
                        wrapMode: Text.WordWrap
                        font.pixelSize: 11
                    }

                    AppButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Retry"
                        compact: true
                        onClicked: root.retry()
                    }
                }
            }
        }
    }

    Loader {
        id: devToolsLoader
        x: root.frameWidth * root.presentationScale + 12
        active: root.devToolsVisible
        sourceComponent: Component {
            WebEngineView {
                width: root.devToolsWidth
                height: root.height
                backgroundColor: Theme.panel
                inspectedView: webView
            }
        }
    }

    Connections {
        target: root.device

        function onProfileChanged() {
            webView.reload()
        }
    }

    Connections {
        target: devToolsLoader

        function onItemChanged() {
            webView.devToolsView = devToolsLoader.item
        }
    }
}
