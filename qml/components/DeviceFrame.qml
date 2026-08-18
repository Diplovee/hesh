import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtWebEngine
import Hesh 1.0

pragma ComponentBehavior: Bound

Item {
    id: root

    property var device
    property var manager
    property real availableWidth: 620
    property real availableHeight: 560
    property int bezel: 12
    property int screenRadius: 14
    property bool frameChromeVisible: true
    property string fitMode: "Fit"
    property real manualScale: 1.0
    // Keep the browser at the device's logical viewport. The complete web
    // surface is then presented at the selected scale so CSS layout and the
    // visible device frame use the same coordinate system.
    property real userZoomFactor: 1.0
    property bool devToolsVisible: false
    property bool persistManualScale: true
    property bool physicalWebSurface: false
    property real pageDevicePixelRatio: 0.0
    property int devToolsWidth: 360

    readonly property real logicalWidth: root.device ? root.device.logicalViewportWidth : 0
    readonly property real logicalHeight: root.device ? root.device.logicalViewportHeight : 0
    readonly property real chromeInset: root.frameChromeVisible ? root.bezel : 0
    readonly property real frameWidth: root.logicalWidth + root.chromeInset * 2
    readonly property real frameHeight: root.logicalHeight + root.chromeInset * 2
    readonly property real fitAvailableWidth: Math.max(1, root.availableWidth
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
    readonly property real webZoomFactor: Math.max(0.25,
                                                   Math.min(3.0,
                                                            (root.physicalWebSurface
                                                             ? root.presentationScale
                                                             : 1.0) * root.userZoomFactor))
    readonly property int presentationPercent: Math.round(root.presentationScale * 100)
    readonly property string presentationMode: root.fitMode === "Fit" ? "Fit" : "Scale"
    readonly property bool isLoading: root.device ? root.device.loading : false
    readonly property bool pageLoaded: root.device ? root.device.runtimeState === "Loaded" : false
    readonly property bool canGoBack: webView.canGoBack
    readonly property bool canGoForward: webView.canGoForward
    readonly property real webSurfaceWidth: contentSurface.width
    readonly property real estimatedPageDevicePixelRatio: root.physicalWebSurface
                                                          && Screen.devicePixelRatio > 0
                                                          ? Screen.devicePixelRatio * root.webZoomFactor
                                                          : 0.0
    readonly property real effectivePageDevicePixelRatio: root.pageDevicePixelRatio > 0
                                                           && (root.estimatedPageDevicePixelRatio <= 0
                                                               || Math.abs(root.pageDevicePixelRatio
                                                                           - root.estimatedPageDevicePixelRatio)
                                                                  <= root.estimatedPageDevicePixelRatio * 0.15)
                                                           ? root.pageDevicePixelRatio
                                                           : root.estimatedPageDevicePixelRatio
    readonly property real webBackingScaleCorrection: root.physicalWebSurface && Screen.devicePixelRatio > 0
                                                      && root.effectivePageDevicePixelRatio > 0
                                                      ? Screen.devicePixelRatio / root.effectivePageDevicePixelRatio
                                                      : 1.0
    // Calibration for Qt WebEngine's fractional Wayland backing-texture crop.
    // Keep this as an explicit constant: changing the WebEngine width is not
    // a valid substitute because it changes the page's CSS viewport.
    readonly property real webCompositorOffsetFactor: 0.83
    readonly property real webContentOffset: root.physicalWebSurface
                                             ? root.webSurfaceWidth
                                               * (root.webBackingScaleCorrection - 1.0) / 2.0
                                               // Preserve the CSS viewport while compensating for
                                               // Qt WebEngine's fractional backing-texture crop.
                                               * root.webCompositorOffsetFactor
                                             : 0.0

    width: root.device ? root.frameWidth * root.presentationScale
                       : 0
    height: root.device ? root.frameHeight * root.presentationScale : 0

    function setScale(scale) {
        if (root.device) {
            root.device.manualScale = scale
            root.device.fitMode = "Manual"
        } else {
            root.manualScale = scale
            root.fitMode = "Manual"
        }
    }

    function useFit() {
        if (root.device)
            root.device.fitMode = "Fit"
        else
            root.fitMode = "Fit"
    }

    function navigate() {
        if (root.device && root.device.url.length > 0) {
            webView.url = root.device.url
        }
    }

    function navigateTo(requestedUrl) {
        return root.device && root.device.navigateTo(requestedUrl)
    }

    function goBack() {
        if (webView.canGoBack)
            webView.goBack()
    }

    function goForward() {
        if (webView.canGoForward)
            webView.goForward()
    }

    function reload() {
        webView.reload()
    }

    function hardReload() {
        webView.reloadAndBypassCache()
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

    function hardRetry() {
        root.navigate()
        webView.reloadAndBypassCache()
    }

    function syncWebZoom() {
        if (Math.abs(webView.zoomFactor - root.webZoomFactor) > 0.001)
            webView.zoomFactor = root.webZoomFactor
    }

    function syncPageDevicePixelRatio() {
        webView.runJavaScript("window.devicePixelRatio", function(value) {
            const ratio = Number(value)
            const expected = root.estimatedPageDevicePixelRatio
            if (isFinite(ratio) && ratio > 0
                && (!root.physicalWebSurface || expected <= 0
                    || Math.abs(ratio - expected) <= expected * 0.15)
                && Math.abs(root.pageDevicePixelRatio - ratio) > 0.001) {
                root.pageDevicePixelRatio = ratio
            }
        })
    }

    function zoomIn() {
        root.userZoomFactor = Math.min(3.0, root.userZoomFactor + 0.1)
        root.syncWebZoom()
    }

    function zoomOut() {
        root.userZoomFactor = Math.max(0.25, root.userZoomFactor - 0.1)
        root.syncWebZoom()
    }

    onPresentationScaleChanged: root.syncWebZoom()

    onFitModeChanged: {
        if (root.device && root.device.fitMode !== root.fitMode)
            root.device.fitMode = root.fitMode
    }

    onManualScaleChanged: {
        if (root.persistManualScale && root.device
            && Math.abs(root.device.manualScale - root.manualScale) > 0.001)
            root.device.manualScale = root.manualScale
    }

    onFrameChromeVisibleChanged: {
        if (root.device && root.device.frameChromeVisible !== root.frameChromeVisible)
            root.device.frameChromeVisible = root.frameChromeVisible
    }

    onDevToolsVisibleChanged: {
        if (root.device && root.device.devToolsVisible !== root.devToolsVisible)
            root.device.devToolsVisible = root.devToolsVisible
    }

    Component.onCompleted: {
        root.syncWebZoom()
        root.syncPageDevicePixelRatio()
    }

    Rectangle {
        id: frame
        width: root.frameWidth * root.presentationScale
        height: root.frameHeight * root.presentationScale
        radius: root.frameChromeVisible ? root.screenRadius * root.presentationScale : 0
        color: root.frameChromeVisible ? Theme.panelRaised : "#0d1014"
        border.width: root.frameChromeVisible ? 1 : 0
        border.color: root.frameChromeVisible ? Theme.borderStrong : "transparent"
        clip: true

        Text {
            anchors.top: parent.top
            anchors.topMargin: root.presentationScale
            anchors.horizontalCenter: parent.horizontalCenter
            height: Math.max(1, (root.bezel - 2) * root.presentationScale)
            verticalAlignment: Text.AlignVCenter
            visible: root.frameChromeVisible
            text: root.device ? root.device.profileName : ""
            color: Theme.textFaint
            font.pixelSize: Math.max(1, 9 * root.presentationScale)
            font.weight: Font.Medium
        }

        Rectangle {
            id: contentSurface
            x: root.chromeInset * root.presentationScale
            y: root.chromeInset * root.presentationScale
            width: root.logicalWidth * (root.physicalWebSurface ? root.presentationScale : 1.0)
            height: root.logicalHeight * (root.physicalWebSurface ? root.presentationScale : 1.0)
            scale: root.physicalWebSurface ? 1.0 : root.presentationScale
            transformOrigin: Item.TopLeft
            radius: root.frameChromeVisible
                    ? root.screenRadius * (root.physicalWebSurface ? root.presentationScale : 1.0)
                    : 0
            color: "#0d1014"
            clip: true

            WebEngineView {
                id: webView
                x: -root.webContentOffset
                y: 0
                // Keep this width equal to the visible surface. Expanding it
                // to include webContentOffset makes innerWidth larger than
                // the device viewport and shifts centered web content.
                width: parent.width
                height: parent.height
                // Keep WebEngine at the logical device size. The parent surface
                // scales both the page and its background together.
                zoomFactor: root.webZoomFactor
                // Keep the configured URL mounted while the device lifecycle
                // changes. Switching to about:blank for a transient status
                // update can feed that internal URL back into WebDevice and
                // permanently replace the user's app URL.
                url: root.device ? root.device.url : "about:blank"
                profile: root.device ? root.device.browserProfile : null
                backgroundColor: "#0d1014"
                settings.fullScreenSupportEnabled: false
                settings.javascriptEnabled: true
                // Keep web app state (localStorage/IndexedDB) enabled for the
                // device-specific persistent QQuickWebEngineProfile.
                settings.localStorageEnabled: true
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
                    if (loadRequest.status === WebEngineView.LoadSucceededStatus)
                        root.syncPageDevicePixelRatio()
                    if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                        root.device.discardPendingNavigation()
                        root.device.setRuntimeError(loadRequest.errorString.length > 0
                                                    ? loadRequest.errorString
                                                    : "Navigation failed")
                    } else if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                        root.device.commitPendingNavigation()
                        root.device.setRuntimeLoaded()
                    } else {
                        root.device.setLoading(true)
                    }
                }

                onUrlChanged: {
                    if (root.device && url.toString() !== "about:blank"
                        && url.toString() !== root.device.url)
                        root.device.setPendingNavigationUrl(url.toString())
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

        Connections {
            target: root.device

            function onReloadRequested(bypassCache) {
                if (bypassCache)
                    root.hardReload()
                else
                    root.reload()
            }

            function onNavigationRequested(url) {
                webView.url = url
            }
        }

        Rectangle {
                // Keep the loading surface aligned with WebEngineView. In a
                // physical standalone surface the page is translated to
                // compensate for the fractional backing-texture crop.
                x: -root.webContentOffset
                y: 0
                width: parent.width
                height: parent.height
                z: 2
                visible: !!root.device && root.device.runtimeState === "Loading"
                color: "#0d1014"

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "LOADING"
                        color: Theme.accent
                        font.pixelSize: Math.max(1, 10 * root.presentationScale)
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.7 * root.presentationScale
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.device ? root.device.url : ""
                        color: Theme.textMuted
                        font.pixelSize: Math.max(1, 12 * root.presentationScale)
                    }
                }
            }

            Rectangle {
                x: -root.webContentOffset
                y: 0
                width: parent.width
                height: parent.height
                z: 3
                visible: !!root.device && root.device.runtimeState === "Error"
                color: "#0d1014"

                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 36, 300)
                    spacing: 10

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "COULDN'T REACH"
                        color: Theme.error
                        font.pixelSize: Math.max(1, 10 * root.presentationScale)
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.4 * root.presentationScale
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: root.device ? root.device.url : ""
                        color: Theme.text
                        elide: Text.ElideMiddle
                        font.pixelSize: Math.max(1, 12 * root.presentationScale)
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: root.device ? root.device.errorMessage : "Navigation failed"
                        color: Theme.textMuted
                        wrapMode: Text.WordWrap
                        font.pixelSize: Math.max(1, 11 * root.presentationScale)
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        AppButton {
                            text: "Retry"
                            compact: true
                            onClicked: root.retry()
                        }

                        AppButton {
                            text: "Hard Reload"
                            secondary: true
                            compact: true
                            onClicked: root.hardRetry()
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: 10
                acceptedButtons: Qt.RightButton
                onClicked: function(mouse) {
                    webContextMenu.openAt(contentSurface, mouse.x, mouse.y)
                }
            }
        }
    }

    Connections {
        target: root.device

        function onViewPreferencesChanged() {
            if (!root.device)
                return
            if (root.fitMode !== root.device.fitMode)
                root.fitMode = root.device.fitMode
            if (Math.abs(root.manualScale - root.device.manualScale) > 0.001)
                root.manualScale = root.device.manualScale
            if (root.frameChromeVisible !== root.device.frameChromeVisible)
                root.frameChromeVisible = root.device.frameChromeVisible
            if (root.devToolsVisible !== root.device.devToolsVisible)
                root.devToolsVisible = root.device.devToolsVisible
        }

        function onProfileChanged() {
            webView.reload()
        }
    }

    DevToolsWindow {
        id: devToolsWindow
        device: root.device
        inspectedView: webView
        visible: !!root.device && root.devToolsVisible
    }

    WebContextMenu {
        id: webContextMenu
        device: root.device
        frame: root
        manager: root.manager
    }
}
