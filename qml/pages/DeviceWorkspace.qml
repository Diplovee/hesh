import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hesh 1.0

pragma ComponentBehavior: Bound

Item {
    id: root

    property var device
    property var manager
    signal editDeviceRequested(string deviceId)
    signal duplicateDeviceRequested(string deviceId)
    signal removeDeviceRequested(string deviceId)
    readonly property bool isAndroid: !!root.device && root.device.type === "android"
    property string selectedFit: "Fit"
    readonly property var fitChoices: ["Fit", "25%", "50%", "75%", "100%", "125%"]
    readonly property var deviceFrame: frameLoader.item

    function syncViewPreferences() {
        if (!root.device)
            root.selectedFit = "Fit"
        else if (root.device.fitMode === "Manual")
            root.selectedFit = Math.round(root.device.manualScale * 100) + "%"
        else
            root.selectedFit = "Fit"
    }

    function toggleFrameChrome() {
        if (root.device && !root.isAndroid)
            root.device.frameChromeVisible = !root.device.frameChromeVisible
    }

    function applyFit(choice) {
        root.selectedFit = choice
        if (!frameLoader.item)
            return
        if (choice === "Fit")
            frameLoader.item.useFit()
        else
            frameLoader.item.setScale(Number(choice.replace("%", "")) / 100.0)
    }

    function returnToEmbedded() {
        if (root.manager && root.device)
            root.manager.returnToEmbedded(root.device.id)
    }

    function reloadDevice(hard) {
        if (!root.device)
            return
        if (root.isAndroid) {
            if (hard)
                root.device.hardReload()
            else
                root.device.reload()
        } else {
            // Calling the device API also reaches a detached WebEngineView,
            // while preserving the selected-device shortcut target.
            if (hard)
                root.device.hardReload()
            else
                root.device.reload()
        }
    }

    function toggleStandalone() {
        if (!root.manager || !root.device || root.isAndroid)
            return
        if (root.device.presentationState === "Standalone")
            root.returnToEmbedded()
        else
            root.manager.openStandalone(root.device.id)
    }

    function toggleDevTools() {
        if (root.device && !root.isAndroid)
            root.device.devToolsVisible = !root.device.devToolsVisible
    }

    function focusUrl() {
        if (!root.isAndroid) {
            urlField.forceActiveFocus()
            urlField.selectAll()
        }
    }

    function setShortcutScale(choice) {
        root.applyFit(choice)
    }

    function rotateDevice() {
        if (!root.device)
            return
        if (root.isAndroid)
            root.device.rotateDevice()
        else
            root.device.orientation = root.device.orientation === "Landscape" ? "Portrait" : "Landscape"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            Layout.leftMargin: 30
            Layout.rightMargin: 28
            spacing: 12

            ColumnLayout {
                spacing: 3

                Text {
                    text: root.device ? root.device.name : ""
                    color: Theme.text
                    font.pixelSize: 17
                    font.weight: Font.Medium
                }

                Text {
                    text: root.device
                          ? root.device.typeLabel + " DEVICE  /  " + root.device.profileName
                          : ""
                    color: Theme.textMuted
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.9
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }

            Text {
                visible: !root.isAndroid && !!root.device
                         && root.device.presentationState === "Standalone"
                text: "OPEN IN WINDOW"
                color: Theme.accent
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 0.9
            }

            IconButton {
                id: menuButton
                iconText: "⋯"
                enabled: !!root.device
                onClicked: deviceMenu.openFor(menuButton)
            }
        }

        DeviceContextMenu {
            id: deviceMenu
            manager: root.manager
            deviceId: root.device ? root.device.id : ""
            deviceName: root.device ? root.device.name : ""
            deviceType: root.device ? root.device.type : "web"
            deviceStatus: root.device ? root.device.status : "Stopped"
            devicePresentationState: root.device && root.device.type === "web"
                                     ? root.device.presentationState : "Embedded"
            onEditRequested: root.editDeviceRequested(root.device ? root.device.id : "")
            onDuplicateRequested: root.duplicateDeviceRequested(root.device ? root.device.id : "")
            onRemoveRequested: root.removeDeviceRequested(root.device ? root.device.id : "")
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            Layout.leftMargin: 30
            Layout.rightMargin: 28
            spacing: 5

            IconButton {
                iconText: "‹"
                tooltip: "Back"
                visible: !root.isAndroid
                enabled: !!frameLoader.item && !!frameLoader.item.canGoBack
                onClicked: frameLoader.item.goBack()
            }

            IconButton {
                iconText: "›"
                tooltip: "Forward"
                visible: !root.isAndroid
                enabled: !!frameLoader.item && !!frameLoader.item.canGoForward
                onClicked: frameLoader.item.goForward()
            }

            IconButton {
                iconText: frameLoader.item && frameLoader.item.isLoading ? "×" : "↻"
                tooltip: frameLoader.item && frameLoader.item.isLoading ? "Stop" : "Reload"
                visible: !root.isAndroid
                enabled: frameLoader.item !== null
                onClicked: frameLoader.item.reloadOrStop()
            }

            TextField {
                id: urlField
                visible: !root.isAndroid
                Layout.fillWidth: true
                implicitHeight: 32
                text: !root.isAndroid && root.device ? root.device.url : ""
                color: Theme.text
                placeholderText: "Enter a URL"
                placeholderTextColor: Theme.textFaint
                font.pixelSize: 11
                selectByMouse: true
                inputMethodHints: Qt.ImhUrlCharactersOnly
                leftPadding: 10
                rightPadding: 10
                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.input
                    border.width: 1
                    border.color: parent.activeFocus ? Theme.accentStrong : Theme.border
                }
                onAccepted: {
                    if (root.device) {
                        if (frameLoader.item && !frameLoader.item.navigateTo(text))
                            root.device.setRuntimeError("Enter a valid http or https URL")
                    }
                    focus = false
                }
            }

            ComboBox {
                id: recentUrlCombo
                visible: !root.isAndroid && !!root.device
                implicitWidth: 142
                implicitHeight: 32
                model: root.device ? root.device.recentUrls : []
                leftPadding: 8
                rightPadding: 22
                contentItem: Text {
                    text: recentUrlCombo.displayText.length > 0 ? recentUrlCombo.displayText : "Recent URLs"
                    color: Theme.textMuted
                    elide: Text.ElideMiddle
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 10
                }
                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.input
                    border.width: 1
                    border.color: recentUrlCombo.activeFocus ? Theme.accentStrong : Theme.border
                }
                onActivated: {
                    if (frameLoader.item)
                        frameLoader.item.navigateTo(currentText)
                }
            }

            AppButton {
                visible: !root.isAndroid
                text: !root.isAndroid && root.device && root.device.presentationState === "Standalone"
                      ? "Return to Hesh" : "Open in Window"
                compact: true
                secondary: !root.isAndroid && !!root.device
                           && root.device.presentationState === "Standalone"
                enabled: !!root.device
                onClicked: {
                    if (!root.manager || !root.device)
                        return
                    if (root.device.presentationState === "Standalone")
                        root.returnToEmbedded()
                    else
                        root.manager.openStandalone(root.device.id)
                }
            }

            Text {
                visible: root.isAndroid
                Layout.fillWidth: true
                text: root.manager && !root.manager.androidFeatureEnabled
                      ? "LOCKED  ·  resource limit"
                      : (root.device
                         ? root.device.runtimeState + "  ·  " + root.device.adbSerial
                         : "Android runtime")
                color: root.manager && !root.manager.androidFeatureEnabled
                       ? Theme.warning
                       : (root.device && root.device.status === "Error" ? Theme.error : Theme.textMuted)
                elide: Text.ElideMiddle
                font.pixelSize: 11
            }

            AppButton {
                visible: root.isAndroid
                text: "Open Android Display"
                compact: true
                enabled: !!root.device && !!root.device.booted
                         && !!root.manager && !!root.manager.androidFeatureEnabled
                onClicked: if (root.device) root.device.openDisplay()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: stage
                anchors.fill: parent

                Loader {
                    id: frameLoader
                    anchors.centerIn: parent
                    active: root.isAndroid || (root.device && root.device.presentationState !== "Standalone")
                    sourceComponent: root.isAndroid ? androidFrameComponent : webFrameComponent
                    onItemChanged: {
                        root.syncViewPreferences()
                        root.applyFit(root.selectedFit)
                    }
                }

                Component {
                    id: webFrameComponent

                    DeviceFrame {
                        device: root.device
                        manager: root.manager
                        availableWidth: stage.width
                        availableHeight: stage.height
                        fitMode: root.device ? root.device.fitMode : "Fit"
                        manualScale: root.device ? root.device.manualScale : 1.0
                        frameChromeVisible: root.device ? root.device.frameChromeVisible : true
                        devToolsVisible: root.device ? root.device.devToolsVisible : false
                    }
                }

                Component {
                    id: androidFrameComponent

                    AndroidFrame {
                        device: root.device
                        manager: root.manager
                        availableWidth: stage.width
                        availableHeight: stage.height
                    }
                }

                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 40, 360)
                    spacing: 12
                    visible: !root.isAndroid && !!root.device
                             && root.device.presentationState === "Standalone"

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.device ? root.device.name + " is open in a separate window" : ""
                        color: Theme.text
                        font.pixelSize: 14
                        font.weight: Font.Medium
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "The live device surface is detached from this workspace."
                        color: Theme.textMuted
                        wrapMode: Text.WordWrap
                        font.pixelSize: 11
                    }

                    AppButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Return to Hesh"
                        secondary: true
                        compact: true
                        onClicked: root.returnToEmbedded()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: Theme.panel
            border.width: 1
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 30
                anchors.rightMargin: 28
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.isAndroid
                          ? (root.device ? root.device.avdName : "")
                          : (root.device ? root.device.url : "")
                    color: Theme.textMuted
                    elide: Text.ElideMiddle
                    font.pixelSize: 10
                }

                Text {
                    text: root.device
                          ? (root.isAndroid
                             ? root.device.viewportWidth + " × " + root.device.viewportHeight
                             : root.device.logicalViewportWidth + " × " + root.device.logicalViewportHeight)
                          : ""
                    color: Theme.text
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }

                Text {
                    text: root.device ? "DPR " + Number(root.device.devicePixelRatio).toFixed(2) : ""
                    color: Theme.textMuted
                    font.pixelSize: 10
                }

                ComboBox {
                    id: fitCombo
                    visible: !root.isAndroid
                    implicitWidth: 74
                    implicitHeight: 30
                    model: root.fitChoices
                    currentIndex: Math.max(0, root.fitChoices.indexOf(root.selectedFit))
                    leftPadding: 8
                    rightPadding: 22
                    contentItem: Text {
                        text: fitCombo.displayText
                        color: Theme.textMuted
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 10
                    }
                    background: Rectangle {
                        radius: Theme.radiusSmall
                        color: Theme.input
                        border.width: 1
                        border.color: fitCombo.activeFocus ? Theme.accentStrong : Theme.border
                    }
                    onActivated: root.applyFit(currentText)
                }

                IconButton {
                    iconText: "−"
                    visible: !root.isAndroid
                    tooltip: "Zoom out"
                    enabled: frameLoader.item !== null
                    onClicked: frameLoader.item.zoomOut()
                }

                IconButton {
                    iconText: "+"
                    visible: !root.isAndroid
                    tooltip: "Zoom in"
                    enabled: frameLoader.item !== null
                    onClicked: frameLoader.item.zoomIn()
                }

                AppButton {
                    visible: !root.isAndroid
                    text: root.device && root.device.orientation === "Landscape" ? "Portrait" : "Landscape"
                    compact: true
                    secondary: true
                    enabled: !!root.device
                    onClicked: if (root.device) root.device.orientation = root.device.orientation === "Landscape" ? "Portrait" : "Landscape"
                }

                AppButton {
                    visible: !root.isAndroid
                    text: frameLoader.item && frameLoader.item.frameChromeVisible ? "Hide Frame" : "Show Frame"
                    compact: true
                    secondary: true
                    enabled: frameLoader.item !== null
                    onClicked: root.toggleFrameChrome()
                }

                AppButton {
                    visible: !root.isAndroid
                    text: frameLoader.item && frameLoader.item.devToolsVisible ? "Hide DevTools" : "DevTools"
                    compact: true
                    secondary: true
                    enabled: frameLoader.item !== null
                    onClicked: root.toggleDevTools()
                }

                Text {
                    text: frameLoader.item
                          ? frameLoader.item.presentationMode + " · "
                            + frameLoader.item.presentationPercent + "%" : ""
                    color: Theme.accent
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    Connections {
        target: root.isAndroid ? null : root.device

        function onViewPreferencesChanged() {
            root.syncViewPreferences()
        }

        function onUrlChanged() {
            if (!urlField.activeFocus)
                urlField.text = root.device ? root.device.url : ""
        }
    }

    onDeviceChanged: {
        root.syncViewPreferences()
        urlField.text = root.device ? root.device.url : ""
    }
}
