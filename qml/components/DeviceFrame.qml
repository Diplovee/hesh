import QtQuick
import QtQuick.Shapes
import QtCore
import QtWebEngine
import Hesh 1.0

Item {
    id: root

    property var device: null
    property real availableWidth: 620
    property real availableHeight: 560
    property int bezel: 12
    property int screenRadius: 14
    // Embedded previews keep the device bezel and fit down to the workspace.
    // Standalone hosts turn the chrome off and may scale in either direction
    // while preserving the browser's logical viewport dimensions.
    property bool showChrome: true
    property bool allowUpscale: false
    property real presentationPadding: root.showChrome ? 32 : 0
    property real minimumPresentationScale: root.allowUpscale ? 0.01 : 0.1
    property real maximumPresentationScale: root.allowUpscale ? 8.0 : 1.0
    property bool pageLoaded: false
    property bool pageLoading: false
    property bool pageFailed: false
    property string pageError: ""
    property bool profileReady: false
    property bool showDevTools: false
    property int devToolsWidth: 420
    property bool devToolsThemeApplied: false
    property int devToolsThemeAttempts: 0

    function localPath(location) {
        // StandardPaths returns a URL in QML, while WebEngineProfile expects a
        // native filesystem path. Passing the URL verbatim creates a literal
        // "file:" directory relative to the process working directory.
        return decodeURIComponent(location.toString().replace(/^file:\/\//, ""))
    }

    function applyDevToolsDarkTheme() {
        if (!root.showDevTools || root.devToolsThemeApplied
                || devToolsView.loading || devToolsView.url.toString() === "") {
            return
        }

        // DevTools has its own preference store. Chromium's process theme and
        // WebEngineSettings.forceDarkMode do not reliably select this setting.
        devToolsView.runJavaScript(
            "(() => {" +
            "  try {" +
            "    const settings = globalThis.Common?.settings ?? " +
            "      globalThis.Common?.Settings?.Settings?.instance?.();" +
            "    if (!settings) return false;" +
            "    let theme;" +
            "    try { theme = settings.moduleSetting('uiTheme'); } catch (_) {}" +
            "    theme ||= settings.createSetting('uiTheme', 'systemPreferred');" +
            "    if (theme.get() !== 'dark') theme.set('dark');" +
            "    return theme.get() === 'dark';" +
            "  } catch (_) { return false; }" +
            "})()",
            function(applied) {
                root.devToolsThemeApplied = applied === true
            })
    }

    onShowDevToolsChanged: {
        if (root.showDevTools) {
            root.devToolsThemeApplied = false
            root.devToolsThemeAttempts = 0
            devToolsThemeTimer.restart()
        } else {
            devToolsThemeTimer.stop()
        }
    }

    Timer {
        id: devToolsThemeTimer
        interval: 150
        repeat: true
        running: root.showDevTools && !root.devToolsThemeApplied
        onTriggered: {
            root.devToolsThemeAttempts++
            root.applyDevToolsDarkTheme()
            if (root.devToolsThemeApplied || root.devToolsThemeAttempts >= 40) stop()
        }
    }

    // The content item remains the logical viewport. Only the outer frame is scaled.
    property real presentationScale: root.device
                                      ? Math.min(root.maximumPresentationScale,
                                                 Math.max(root.minimumPresentationScale, (root.availableWidth
                                                          - root.presentationPadding
                                                          - (root.showDevTools ? root.devToolsWidth + 16 : 0))
                                                          / (root.device.viewportWidth + root.bezel * 2)),
                                                 Math.max(root.minimumPresentationScale, (root.availableHeight
                                                          - root.presentationPadding)
                                                          / (root.device.viewportHeight + root.bezel * 2)))
                                      : 1.0
    readonly property int presentationPercent: Math.round(root.presentationScale * 100)
    readonly property string presentationMode: root.allowUpscale ? "Scale" : "Fit"
    readonly property bool canGoBack: webView.canGoBack
    readonly property bool canGoForward: webView.canGoForward

    function reloadPage() { webView.reload() }
    function goBack() { webView.goBack() }
    function goForward() { webView.goForward() }

    width: root.device
           ? (root.device.viewportWidth + root.bezel * 2) * root.presentationScale
             + (root.showDevTools ? root.devToolsWidth + 16 : 0)
           : 0
    height: root.device
            ? (root.device.viewportHeight + root.bezel * 2) * root.presentationScale
            : 0

    onDeviceChanged: {
        root.pageLoaded = false
        root.pageLoading = false
        root.pageFailed = false
        root.pageError = ""
    }

    // Every device gets its own browser profile. This keeps localStorage,
    // IndexedDB, cookies and cache isolated and available after a reload.
    WebEngineProfilePrototype {
        id: deviceProfile
        storageName: root.device ? "hesh-device-" + root.device.id : "hesh-device-preview"
        persistentStoragePath: root.device
            ? root.localPath(StandardPaths.writableLocation(StandardPaths.AppDataLocation))
              + "/web-devices/" + root.device.id
            : ""
        cachePath: root.device
            ? root.localPath(StandardPaths.writableLocation(StandardPaths.CacheLocation))
              + "/web-devices/" + root.device.id
            : ""
        httpCacheType: WebEngineProfile.DiskHttpCache
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
    }

    Component.onCompleted: {
        // Assign after construction; assigning instance() through a binding
        // during WebEngineView creation can crash Qt WebEngine on Wayland.
        var profile = deviceProfile.instance()
        if (root.device && root.device.userAgent) {
            profile.httpUserAgent = root.device.userAgent
        }
        webView.profile = profile
        root.profileReady = true
    }

    Rectangle {
        id: frame
        width: root.device ? root.device.viewportWidth + root.bezel * 2 : 0
        height: root.device ? root.device.viewportHeight + root.bezel * 2 : 0
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.showDevTools ? 0 : (root.width - width) / 2
        scale: root.presentationScale
        transformOrigin: Item.Center
        smooth: true
        antialiasing: true
        radius: root.showChrome ? root.screenRadius : 0
        color: root.showChrome ? Theme.panelRaised : "transparent"
        border.width: root.showChrome ? 1 : 0
        border.color: root.showChrome ? Theme.borderStrong : "transparent"
        clip: true

        Text {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            height: root.bezel - 2
            verticalAlignment: Text.AlignVCenter
            text: root.device ? root.device.profileName : ""
            visible: root.showChrome
            color: Theme.textFaint
            font.pixelSize: 9
            font.weight: Font.Medium
        }

        Rectangle {
            id: contentSurface
            anchors.fill: parent
            anchors.margins: root.bezel
            radius: root.showChrome ? root.screenRadius : 0
            color: "#0d1014"
            border.width: 0
            clip: true
            smooth: true

            Rectangle {
                anchors.fill: parent
                color: "#0d1014"
                z: 1
                visible: !root.pageLoaded

                Column {
                    anchors.centerIn: parent
                    spacing: 9

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "WEB DEVICE"
                        color: Theme.accent
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.7
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.pageFailed ? "Unable to load preview" : (root.pageLoading ? "Loading preview…" : (root.device ? root.device.url : ""))
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.pageFailed
                        text: root.pageError
                        color: Theme.error
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                    }

                    AppButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.pageFailed
                        text: "Retry"
                        compact: true
                        onClicked: webView.reload()
                    }
                }
            }

            WebEngineView {
                id: webView
                anchors.fill: parent
                z: 0
                url: root.profileReady && root.device && root.device.status === "Running"
                     ? root.device.url : "about:blank"
                // Keep page layout at the profile's logical viewport while
                // retaining the GPU-backed raster path for crisp scaled output.
                zoomFactor: 1.0
                backgroundColor: "#0d1014"
                settings.accelerated2dCanvasEnabled: true
                settings.webGLEnabled: true
                settings.fullScreenSupportEnabled: false
                settings.javascriptEnabled: true
                settings.localContentCanAccessRemoteUrls: true
                onLoadProgressChanged: {
                    // loadingChanged can arrive late for development servers.
                    // Reveal the page as soon as Chromium has rendered it.
                    if (loadProgress >= 100) {
                        root.pageLoading = false
                        root.pageLoaded = true
                        root.pageFailed = false
                    }
                }
                onLoadingChanged: function(loadRequest) {
                    if (loadRequest.status === WebEngineView.LoadStartedStatus) {
                        root.pageLoading = true
                        root.pageLoaded = false
                        root.pageFailed = false
                        root.pageError = ""
                    } else if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                        root.pageLoading = false
                        root.pageLoaded = true
                        root.pageFailed = false
                    } else if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                        root.pageLoading = false
                        root.pageLoaded = false
                        root.pageFailed = true
                        root.pageError = loadRequest.errorString || "Check that the URL is running."
                        console.info("Hesh WebDevice could not load", loadRequest.url, loadRequest.errorString)
                    }
                }
            }

            Shape {
                width: root.screenRadius
                height: root.screenRadius
                visible: root.showChrome
                anchors.left: parent.left
                anchors.top: parent.top
                z: 2

                ShapePath {
                    fillColor: Theme.panelRaised
                    strokeColor: "transparent"
                    startX: 0
                    startY: 0
                    PathLine { x: root.screenRadius; y: 0 }
                    PathCubic {
                        control1X: root.screenRadius * 0.4477
                        control1Y: 0
                        control2X: 0
                        control2Y: root.screenRadius * 0.4477
                        x: 0
                        y: root.screenRadius
                    }
                    PathLine { x: 0; y: 0 }
                }
            }

            Shape {
                width: root.screenRadius
                height: root.screenRadius
                visible: root.showChrome
                anchors.right: parent.right
                anchors.top: parent.top
                z: 2

                ShapePath {
                    fillColor: Theme.panelRaised
                    strokeColor: "transparent"
                    startX: 0
                    startY: 0
                    PathLine { x: root.screenRadius; y: 0 }
                    PathLine { x: root.screenRadius; y: root.screenRadius }
                    PathCubic {
                        control1X: root.screenRadius
                        control1Y: root.screenRadius * 0.4477
                        control2X: root.screenRadius * 0.5523
                        control2Y: 0
                        x: 0
                        y: 0
                    }
                }
            }

            Shape {
                width: root.screenRadius
                height: root.screenRadius
                visible: root.showChrome
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                z: 2

                ShapePath {
                    fillColor: Theme.panelRaised
                    strokeColor: "transparent"
                    startX: 0
                    startY: 0
                    PathLine { x: 0; y: root.screenRadius }
                    PathLine { x: root.screenRadius; y: root.screenRadius }
                    PathCubic {
                        control1X: root.screenRadius * 0.4477
                        control1Y: root.screenRadius
                        control2X: 0
                        control2Y: root.screenRadius * 0.5523
                        x: 0
                        y: 0
                    }
                }
            }

            Shape {
                width: root.screenRadius
                height: root.screenRadius
                visible: root.showChrome
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                z: 2

                ShapePath {
                    fillColor: Theme.panelRaised
                    strokeColor: "transparent"
                    startX: 0
                    startY: root.screenRadius
                    PathLine { x: root.screenRadius; y: root.screenRadius }
                    PathLine { x: root.screenRadius; y: 0 }
                    PathCubic {
                        control1X: root.screenRadius * 0.5523
                        control1Y: root.screenRadius
                        control2X: root.screenRadius
                        control2Y: root.screenRadius * 0.4477
                        x: 0
                        y: root.screenRadius
                    }
                }
            }
        }
    }

    Rectangle {
        id: devToolsPanel
        visible: root.showDevTools
        x: (root.device ? (root.device.viewportWidth + root.bezel * 2)
             * (1 + root.presentationScale) / 2 : 0) + 16
        y: 0
        width: root.devToolsWidth
        height: root.height
        color: Theme.panelRaised
        border.width: 1
        border.color: Theme.borderStrong
        radius: root.screenRadius
        clip: true

        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: 14
            height: 34
            verticalAlignment: Text.AlignVCenter
            text: "DEVTOOLS"
            color: Theme.textMuted
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 1.2
        }

        IconButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 4
            anchors.rightMargin: 5
            iconText: "×"
            tooltip: "Close DevTools"
            onClicked: root.showDevTools = false
        }

        WebEngineView {
            id: devToolsView
            anchors.top: parent.top
            anchors.topMargin: 34
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            inspectedView: webView
            backgroundColor: Theme.panelRaised
            onLoadingChanged: function(loadRequest) {
                if (loadRequest.status === WebEngineView.LoadStartedStatus) {
                    root.devToolsThemeApplied = false
                    root.devToolsThemeAttempts = 0
                } else if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                    devToolsThemeTimer.restart()
                    root.applyDevToolsDarkTheme()
                }
            }
        }
    }
}
