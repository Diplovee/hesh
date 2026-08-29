import QtQuick
import QtQuick.Window
import Hesh 1.0

pragma ComponentBehavior: Bound

// A real top-level window is deliberately created without a transient parent.
// This lets a Wayland compositor treat each device as an independent surface.
Window {
    id: root

    property var device: null
    property string deviceId: ""
    property bool browserSurfaceActive: browserLoader.active
    property bool suppressCloseSignal: false
    // Window dimensions are device-independent pixels. Use the compositor's
    // available work area (which excludes reserved bars/panels) and never
    // enlarge the logical viewport; upscaling the WebEngine surface is what
    // makes portrait previews look soft on fractional-scale displays.
    readonly property real viewportWidth: root.device ? Math.max(1, Number(root.device.viewportWidth)) : 412
    readonly property real viewportHeight: root.device ? Math.max(1, Number(root.device.viewportHeight)) : 915
    readonly property real availableScreenWidth: Screen.desktopAvailableWidth > 0
                                                 ? Screen.desktopAvailableWidth : 1200
    readonly property real availableScreenHeight: Screen.desktopAvailableHeight > 0
                                                  ? Screen.desktopAvailableHeight : 675
    readonly property real workAreaVerticalMargin: 64
    readonly property real initialPresentationScale: root.device
                                                     ? Math.min(1.0,
                                                                Math.max(1, root.availableScreenWidth - 32) / root.viewportWidth,
                                                                Math.max(1, root.availableScreenHeight - root.workAreaVerticalMargin) / root.viewportHeight)
                                                     : 1.0

    signal closedByUser(string id)
    signal deviceUnavailable(string id)
    signal focusChanged(string id, bool focused)

    visible: false
    flags: Qt.Window | Qt.FramelessWindowHint
    transientParent: null
    color: Theme.window
    title: root.device ? root.device.name + " — Hesh" : "Hesh"
    width: Math.max(1, Math.round(root.viewportWidth * root.initialPresentationScale))
    height: Math.max(1, Math.round(root.viewportHeight * root.initialPresentationScale))
    minimumWidth: 1
    minimumHeight: 1

    onDeviceChanged: {
        if (root.device) root.deviceId = root.device.id
    }

    onActiveChanged: root.focusChanged(root.deviceId, root.active)

    function focusWindow() {
        if (!root.visible) {
            root.show()
        }
        root.raise()
        root.requestActivate()
    }

    // Main.qml calls this before restoring the embedded host. Keeping the
    // browser Loader explicit makes the destroy-before-restore ordering clear.
    function releaseBrowserSurface() {
        browserLoader.active = false
    }

    function closeForDeviceRemoval() {
        releaseBrowserSurface()
        root.suppressCloseSignal = true
        root.close()
    }

    onClosing: function(closeEvent) {
        releaseBrowserSurface()
        if (!root.suppressCloseSignal) root.closedByUser(root.deviceId)
    }

    Connections {
        target: root.device
        ignoreUnknownSignals: true
        function onDestroyed() {
            root.deviceUnavailable(root.deviceId)
        }
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        color: Theme.window

        Loader {
            id: browserLoader
            anchors.centerIn: parent
            active: root.device !== null
            sourceComponent: DeviceFrame {
                device: root.device
                availableWidth: root.width
                availableHeight: root.height
                bezel: 0
                screenRadius: 0
                showChrome: false
                allowUpscale: false
                presentationPadding: 0
                showDevTools: false
            }
        }

        MouseArea {
            // Only right-click is handled here; ordinary page clicks and
            // scrolling continue to go directly to WebEngineView.
            anchors.fill: parent
            z: 4
            acceptedButtons: Qt.RightButton
            onPressed: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    standaloneMenu.openAt(mouse.x, mouse.y)
                }
            }
        }

        StandaloneContextMenu {
            id: standaloneMenu
            parent: surface
            z: 10
            device: root.device
            canGoBack: browserLoader.item ? browserLoader.item.canGoBack : false
            canGoForward: browserLoader.item ? browserLoader.item.canGoForward : false
            onReloadRequested: if (browserLoader.item) browserLoader.item.reloadPage()
            onBackRequested: if (browserLoader.item) browserLoader.item.goBack()
            onForwardRequested: if (browserLoader.item) browserLoader.item.goForward()
            onCloseRequested: root.close()
        }
    }
}
