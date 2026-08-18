import QtQuick
import QtQuick.Window
import Hesh 1.0

Window {
    id: root

    property var device
    property var manager
    property string scaleMode: device ? device.fitMode : "Fit"
    property real requestedScale: device ? device.manualScale : 1.0
    property bool devToolsVisible: device ? device.devToolsVisible : false
    property bool returningToHesh: false

    readonly property real frameWidth: deviceFrame.frameWidth
    readonly property real frameHeight: deviceFrame.frameHeight
    readonly property real workAreaWidth: root.screen && root.screen.desktopAvailableWidth > 0
                                          ? root.screen.desktopAvailableWidth
                                          : root.frameWidth
    readonly property real workAreaHeight: root.screen && root.screen.desktopAvailableHeight > 0
                                           ? root.screen.desktopAvailableHeight
                                           : root.frameHeight
    readonly property real previewMaxWidth: Math.max(320, root.workAreaWidth * 0.50)
    readonly property real previewMaxHeight: Math.max(320, root.workAreaHeight * 0.88)
    readonly property real fitScale: root.frameWidth > 0 && root.frameHeight > 0
                                     ? Math.max(0.1,
                                                Math.min(1.5,
                                                         root.previewMaxWidth / root.frameWidth,
                                                         root.previewMaxHeight / root.frameHeight))
                                     : 1.0
    readonly property real effectiveScale: Math.max(0.1,
                                                    Math.min(root.scaleMode === "Fit"
                                                             ? root.fitScale
                                                             : root.requestedScale,
                                                             root.fitScale))
    readonly property int nativeWidth: Math.max(1, Math.round(deviceFrame.width))
    readonly property int nativeHeight: Math.max(1, Math.round(deviceFrame.height))

    // Keep this title stable so the compositor can apply the floating rule
    // from the window's initial metadata, before it is mapped.
    visible: false
    color: "#0d1014"
    flags: Qt.Window | Qt.FramelessWindowHint
    title: root.device ? "Hesh Device " + root.device.profileName : "Hesh Device"
    width: root.nativeWidth
    height: root.nativeHeight

    function returnToHesh() {
        if (root.returningToHesh)
            return
        root.returningToHesh = true
        if (root.manager && root.device)
            root.manager.returnToEmbedded(root.device.id)
    }

    function updateNativeGeometry() {
        if (!root.device || root.nativeWidth <= 0 || root.nativeHeight <= 0)
            return
        if (root.width === root.nativeWidth && root.height === root.nativeHeight)
            return
        root.width = root.nativeWidth
        root.height = root.nativeHeight
    }

    function rotateDevice() {
        if (root.device) {
            root.device.orientation = root.device.orientation === "Landscape" ? "Portrait" : "Landscape"
            root.fitToWorkArea()
        }
    }

    function setPresentationScale(scale) {
        if (root.device) {
            root.device.manualScale = scale
            root.device.fitMode = "Manual"
        } else {
            root.scaleMode = "Manual"
            root.requestedScale = scale
        }
        Qt.callLater(function() { root.updateNativeGeometry() })
    }

    function fitToWorkArea() {
        if (root.device)
            root.device.fitMode = "Fit"
        else
            root.scaleMode = "Fit"
        Qt.callLater(function() { root.updateNativeGeometry() })
    }

    onScaleModeChanged: {
        if (root.device && root.device.fitMode !== root.scaleMode)
            root.device.fitMode = root.scaleMode
    }

    onRequestedScaleChanged: {
        if (root.device && root.scaleMode === "Manual"
            && Math.abs(root.device.manualScale - root.requestedScale) > 0.001)
            root.device.manualScale = root.requestedScale
    }

    onDevToolsVisibleChanged: {
        if (root.device && root.device.devToolsVisible !== root.devToolsVisible)
            root.device.devToolsVisible = root.devToolsVisible
    }

    function dispatchShortcut(actionId) {
        switch (actionId) {
        case "window.hide":
            heshApplication.hideToTray()
            root.hide()
            break
        case "window.show":
            heshApplication.requestShow()
            break
        case "window.minimize":
            root.showMinimized()
            break
        case "window.maximize":
            if (root.visibility === Window.Maximized)
                root.showNormal()
            else
                root.showMaximized()
            break
        case "window.close":
            root.close()
            break
        case "app.quit":
            Qt.quit()
            break
        case "device.new":
            heshApplication.requestNewDevice()
            break
        case "device.settings":
            heshApplication.requestShortcutSettings()
            break
        case "device.start":
            if (root.manager && root.device)
                root.manager.startDevice(root.device.id)
            break
        case "device.stop":
            if (root.manager && root.device)
                root.manager.stopDevice(root.device.id)
            break
        case "device.reload":
            if (root.device)
                root.device.reload()
            break
        case "device.hardReload":
            if (root.device)
                root.device.hardReload()
            break
        case "device.rotate":
            root.rotateDevice()
            break
        case "device.openStandalone":
            root.returnToHesh()
            break
        case "web.back":
            deviceFrame.goBack()
            break
        case "web.forward":
            deviceFrame.goForward()
            break
        case "web.focusUrl":
            break
        case "web.devTools":
            if (root.device)
                root.device.devToolsVisible = !root.device.devToolsVisible
            else
                root.devToolsVisible = !root.devToolsVisible
            Qt.callLater(function() { root.updateNativeGeometry() })
            break
        case "view.fit":
            root.fitToWorkArea()
            break
        case "view.scale25":
            root.setPresentationScale(0.25)
            break
        case "view.scale50":
            root.setPresentationScale(0.50)
            break
        case "view.scale75":
            root.setPresentationScale(0.75)
            break
        case "view.scale100":
            root.setPresentationScale(1.0)
            break
        case "view.scale125":
            root.setPresentationScale(1.25)
            break
        }
    }

    onClosing: {
        // Closing the frameless client returns the same device to Hesh. The
        // manager retains the persistent profile and canonical runtime state.
        root.returnToHesh()
    }

    DeviceFrame {
        id: deviceFrame
        device: root.device
        manager: root.manager
        frameChromeVisible: root.device ? root.device.frameChromeVisible : false
        fitMode: root.scaleMode
        manualScale: root.effectiveScale
        persistManualScale: false
        // Standalone windows use the physical surface path. Embedded previews
        // use a logical WebEngine viewport and scale the complete surface in
        // QML; mixing those paths causes fractional text and centering errors.
        physicalWebSurface: true
        devToolsVisible: root.devToolsVisible
        availableWidth: root.workAreaWidth
        availableHeight: root.workAreaHeight
    }

    Connections {
        target: shortcutManager

        function onActionTriggered(actionId, targetDeviceId, origin) {
            if (origin === root.device.id)
                root.dispatchShortcut(actionId)
        }
    }

    Repeater {
        model: shortcutManager

        delegate: Item {
            id: shortcutDelegate
            required property string actionId
            required property string sequence

            Shortcut {
                sequence: shortcutDelegate.sequence
                enabled: root.visible
                context: Qt.WindowShortcut
                onActivated: shortcutManager.trigger(actionId,
                                                     root.device ? root.device.id : "",
                                                     root.device ? root.device.id : "")
            }
        }
    }

    // Only the right button is handled here. Left-clicks continue directly to
    // WebEngineView so normal web interaction is not intercepted.
    MouseArea {
        id: contextMouseArea
        anchors.fill: parent
        z: 10
        acceptedButtons: Qt.RightButton
        onClicked: function(mouse) {
            standaloneContextMenu.openAt(mouse.x, mouse.y)
        }
    }

    StandaloneContextMenu {
        id: standaloneContextMenu
        hostWindow: root
        device: root.device
        frame: deviceFrame
        onReturnToHeshRequested: root.returnToHesh()
        onRotateRequested: root.rotateDevice()
        onFitRequested: root.fitToWorkArea()
        onScaleRequested: function(scale) { root.setPresentationScale(scale) }
        onDevToolsRequested: {
            if (root.device)
                root.device.devToolsVisible = !root.device.devToolsVisible
            else
                root.devToolsVisible = !root.devToolsVisible
            Qt.callLater(function() { root.updateNativeGeometry() })
        }
        onCloseRequested: root.close()
    }

    Component.onCompleted: {
        root.visible = true
        Qt.callLater(function() {
            root.requestActivate()
        })
    }
}
