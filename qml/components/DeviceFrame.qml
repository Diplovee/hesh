import QtQuick
import QtQuick.Shapes
import QtWebEngine
import Hesh 1.0

Item {
    id: root

    property var device
    property real availableWidth: 620
    property real availableHeight: 560
    property int bezel: 12
    property int screenRadius: 14
    property bool pageLoaded: false

    // The content item remains the logical viewport. Only the outer frame is scaled.
    property real presentationScale: root.device
                                      ? Math.min(1.0,
                                                 Math.max(0.1, (root.availableWidth - 32)
                                                          / (root.device.viewportWidth + root.bezel * 2)),
                                                 Math.max(0.1, (root.availableHeight - 32)
                                                          / (root.device.viewportHeight + root.bezel * 2)))
                                      : 1.0
    readonly property int presentationPercent: Math.round(root.presentationScale * 100)
    readonly property string presentationMode: "Fit"

    width: root.device
           ? (root.device.viewportWidth + root.bezel * 2) * root.presentationScale
           : 0
    height: root.device
            ? (root.device.viewportHeight + root.bezel * 2) * root.presentationScale
            : 0

    onDeviceChanged: root.pageLoaded = false

    Rectangle {
        id: frame
        width: root.device ? root.device.viewportWidth + root.bezel * 2 : 0
        height: root.device ? root.device.viewportHeight + root.bezel * 2 : 0
        anchors.centerIn: parent
        scale: root.presentationScale
        transformOrigin: Item.Center
        radius: root.screenRadius
        color: Theme.panelRaised
        border.width: 1
        border.color: Theme.borderStrong
        clip: true

        Text {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            height: root.bezel - 2
            verticalAlignment: Text.AlignVCenter
            text: root.device ? root.device.profileName : ""
            color: Theme.textFaint
            font.pixelSize: 9
            font.weight: Font.Medium
        }

        Rectangle {
            id: contentSurface
            anchors.fill: parent
            anchors.margins: root.bezel
            radius: root.screenRadius
            color: "#0d1014"
            border.width: 0
            clip: true

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
                        text: root.device ? root.device.url : ""
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }
                }
            }

            WebEngineView {
                id: webView
                anchors.fill: parent
                z: 0
                url: root.device && root.device.status === "Running" ? root.device.url : "about:blank"
                backgroundColor: "#0d1014"
                settings.fullScreenSupportEnabled: false
                settings.javascriptEnabled: true
                settings.localContentCanAccessRemoteUrls: true
                onLoadingChanged: function(loadRequest) {
                    root.pageLoaded = loadRequest.status === WebEngineView.LoadSucceededStatus
                    if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                        console.info("Hesh WebDevice could not load", loadRequest.url, loadRequest.errorString)
                    }
                }
            }

            Shape {
                width: root.screenRadius
                height: root.screenRadius
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
}
