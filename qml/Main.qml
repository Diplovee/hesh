import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hesh 1.0

pragma ComponentBehavior: Bound

ApplicationWindow {
    id: window

    visible: true
    width: 1240
    height: 780
    minimumWidth: 900
    minimumHeight: 580
    color: Theme.window
    flags: Qt.Window | Qt.FramelessWindowHint
    title: "Hesh"
    property var standaloneWindows: ({})
    property bool shortcutSettingsOpen: false

    property bool maximized: false

    function openShortcutSettings() {
        window.shortcutSettingsOpen = true
        window.show()
        window.raise()
        window.requestActivate()
    }

    function hideToTray() {
        heshApplication.hideToTray()
        window.hide()
    }

    function dispatchShortcut(actionId, targetDeviceId) {
        const target = targetDeviceId.length > 0 ? targetDeviceId
                                                  : (deviceManager.selectedDevice
                                                     ? deviceManager.selectedDevice.id : "")
        switch (actionId) {
        case "window.hide":
            window.hideToTray()
            break
        case "window.show":
            window.show()
            window.raise()
            window.requestActivate()
            break
        case "window.minimize":
            window.showMinimized()
            break
        case "window.maximize":
            window.toggleMaximize()
            break
        case "window.close":
            Qt.quit()
            break
        case "app.quit":
            Qt.quit()
            break
        case "device.new":
            createDeviceDialog.open()
            break
        case "device.settings":
            window.openShortcutSettings()
            break
        case "device.selectNext":
            deviceManager.selectNextDevice()
            break
        case "device.selectPrevious":
            deviceManager.selectPreviousDevice()
            break
        case "device.start":
            if (target.length > 0)
                deviceManager.startDevice(target)
            break
        case "device.stop":
            if (target.length > 0)
                deviceManager.stopDevice(target)
            break
        case "device.reload":
            workspace.reloadDevice(false)
            break
        case "device.hardReload":
            workspace.reloadDevice(true)
            break
        case "device.rotate":
            workspace.rotateDevice()
            break
        case "device.openStandalone":
            workspace.toggleStandalone()
            break
        case "web.back":
            if (workspace.deviceFrame)
                workspace.deviceFrame.goBack()
            break
        case "web.forward":
            if (workspace.deviceFrame)
                workspace.deviceFrame.goForward()
            break
        case "web.focusUrl":
            workspace.focusUrl()
            break
        case "web.devTools":
            workspace.toggleDevTools()
            break
        case "view.fit":
            workspace.setShortcutScale("Fit")
            break
        case "view.scale25":
            workspace.setShortcutScale("25%")
            break
        case "view.scale50":
            workspace.setShortcutScale("50%")
            break
        case "view.scale75":
            workspace.setShortcutScale("75%")
            break
        case "view.scale100":
            workspace.setShortcutScale("100%")
            break
        case "view.scale125":
            workspace.setShortcutScale("125%")
            break
        case "android.home":
            if (workspace.isAndroid && workspace.device)
                workspace.device.sendHome()
            break
        case "android.back":
            if (workspace.isAndroid && workspace.device)
                workspace.device.sendBack()
            break
        case "android.recents":
            if (workspace.isAndroid && workspace.device)
                workspace.device.sendRecents()
            break
        }
    }
    function toggleMaximize() {
        if (maximized) {
            showNormal()
            maximized = false
        } else {
            showMaximized()
            maximized = true
        }
    }

    function createStandaloneWindow(device) {
        if (!device || standaloneWindows[device.id])
            return

        const created = standaloneWindowComponent.createObject(null, {
            "device": device,
            "manager": deviceManager
        })
        if (!created) {
            deviceManager.returnToEmbedded(device.id)
            return
        }
        standaloneWindows[device.id] = created
    }

    function destroyStandaloneWindow(device) {
        if (!device)
            return
        const existing = standaloneWindows[device.id]
        if (!existing)
            return
        delete standaloneWindows[device.id]
        existing.destroy()
    }

    function closeStandaloneWindows() {
        const ids = Object.keys(standaloneWindows)
        for (let index = 0; index < ids.length; ++index) {
            const existing = standaloneWindows[ids[index]]
            if (existing)
                existing.close()
        }
    }

    Component.onCompleted: {
        if (Qt.application.arguments.indexOf("--maximized") >= 0) {
            showMaximized()
            maximized = true
        }
    }

    onClosing: window.closeStandaloneWindows()

    Connections {
        target: deviceManager

        function onStandaloneRequested(device) {
            window.createStandaloneWindow(device)
        }

        function onEmbeddedRequested(device) {
            window.destroyStandaloneWindow(device)
        }
    }

    Connections {
        target: heshApplication

        function onHideRequested() {
            window.hide()
        }

        function onShowRequested() {
            window.show()
            window.raise()
            window.requestActivate()
        }

        function onShortcutSettingsRequested() {
            window.openShortcutSettings()
        }

        function onNewDeviceRequested() {
            window.show()
            window.raise()
            window.requestActivate()
            createDeviceDialog.open()
        }
    }

    Connections {
        target: shortcutManager

        function onActionTriggered(actionId, targetDeviceId, origin) {
            if (origin === "main")
                window.dispatchShortcut(actionId, targetDeviceId)
        }
    }

    Repeater {
        model: shortcutManager

        delegate: Item {
            id: shortcutDelegate
            required property string actionId
            required property string sequence
            property string targetDeviceId: deviceManager.selectedDevice
                                             ? deviceManager.selectedDevice.id : ""

            Shortcut {
                sequence: shortcutDelegate.sequence
                enabled: window.visible && !window.shortcutSettingsOpen
                context: Qt.WindowShortcut
                onActivated: shortcutManager.trigger(actionId, targetDeviceId, "main")
            }
        }
    }

    Component {
        id: standaloneWindowComponent
        StandaloneDeviceWindow {}
    }

    Rectangle {
        id: shell
        anchors.fill: parent
        color: Theme.window
        border.width: 1
        border.color: Theme.borderStrong
        radius: 8
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: titlebar
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                color: Theme.panel
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 12
                    spacing: 14

                    Image {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        source: "qrc:/qt/qml/Hesh/assets/icons/hesh.png"
                        sourceSize.width: 64
                        sourceSize.height: 64
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Text {
                        text: "HESH"
                        color: Theme.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        font.letterSpacing: 2.0
                    }

                    Text {
                        text: "DEVICE DEVELOPMENT"
                        color: Theme.textFaint
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }

                    Item { Layout.fillWidth: true }

                    AppButton {
                        text: "+  New Device"
                        compact: true
                        onClicked: createDeviceDialog.open()
                    }

                    AppButton {
                        text: "Settings"
                        compact: true
                        secondary: true
                        onClicked: window.openShortcutSettings()
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 22
                        color: Theme.border
                    }

                    IconButton {
                        iconText: "—"
                        tooltip: "Minimize"
                        onClicked: window.showMinimized()
                    }

                    IconButton {
                        iconText: window.maximized ? "❐" : "□"
                        tooltip: window.maximized ? "Restore" : "Maximize"
                        onClicked: window.toggleMaximize()
                    }

                    IconButton {
                        iconText: "×"
                        tooltip: "Close"
                        onClicked: Qt.quit()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    acceptedButtons: Qt.LeftButton
                    onPressed: window.startSystemMove()
                    onDoubleClicked: window.toggleMaximize()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Sidebar {
                    id: sidebar
                    Layout.fillHeight: true
                    Layout.preferredWidth: 252
                    manager: deviceManager
                    onAddDeviceRequested: createDeviceDialog.open()
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.window

                    EmptyState {
                        anchors.fill: parent
                        visible: deviceManager.deviceCount === 0
                        onCreateRequested: createDeviceDialog.open()
                    }

                    DeviceWorkspace {
                        id: workspace
                        anchors.fill: parent
                        visible: deviceManager.deviceCount > 0
                        manager: deviceManager
                        device: deviceManager.selectedDevice
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                color: Theme.panel
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 18

                    Text {
                        text: deviceManager.deviceCount > 0
                              ? (deviceManager.selectedDevice && deviceManager.selectedDevice.type === "android"
                                 ? "Hesh  •  Android runtime"
                                 : "Hesh  •  Web runtime ready")
                              : "Hesh  •  Ready to create a device"
                        color: Theme.textFaint
                        font.pixelSize: 10
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Phase 2"
                        color: Theme.textFaint
                        font.pixelSize: 10
                    }

                    Text {
                        text: "Native device windows  ↗"
                        color: Theme.textMuted
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }

    CreateDeviceDialog {
        id: createDeviceDialog
        manager: deviceManager
    }

    ShortcutSettings {
        id: shortcutSettings
        anchors.fill: shell
        visible: window.shortcutSettingsOpen
        z: 20
        shortcutManager: heshApplication.shortcutManager
        onCloseRequested: window.shortcutSettingsOpen = false
    }
}
