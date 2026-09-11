import QtQuick
import QtQuick.Layouts
import qs.services
import qs.theme
import qs.components

Rectangle {
    id: root

    property string currentMenu: ""
    readonly property bool isExpanded: currentMenu !== ""
    readonly property bool isWifi: currentMenu === "wifi"
    readonly property bool isBluetooth: currentMenu === "bluetooth"
    property bool menuTransitioning: false

    Timer {
        id: menuTransitionTimer
        interval: 400
        repeat: false
        onTriggered: root.menuTransitioning = false
    }

    onIsExpandedChanged: {
        root.menuTransitioning = true;
        menuTransitionTimer.restart();
    }

    readonly property real itemSpacing: Metrics.itemSpacing
    readonly property real sidePadding: Metrics.sidePadding
    readonly property real collapsedLeftX: sidePadding
    readonly property real collapsedWifiX: collapsedLeftX + leftGroup.width + itemSpacing
    readonly property real collapsedBtX: collapsedWifiX + wifiHero.width + itemSpacing
    readonly property real collapsedBatteryX: collapsedBtX + btHero.width + itemSpacing
    readonly property real collapsedWidth: collapsedBatteryX + batteryGroup.width + sidePadding

    readonly property real expandedWidth: Metrics.expandedWidth
    readonly property real expandedHeight: Metrics.expandedHeight
    readonly property real expandedHeroX: Metrics.expandedHeroX

    width: isExpanded ? expandedWidth : collapsedWidth
    height: isExpanded ? expandedHeight : Metrics.islandHeight
    radius: isExpanded ? Metrics.radiusContainer : Metrics.radiusPill
    color: Qt.rgba(Colors.surface_container_lowest.r, Colors.surface_container_lowest.g, Colors.surface_container_lowest.b, Metrics.islandOpacity)
    clip: true

    Behavior on width {
        enabled: root.isExpanded || root.menuTransitioning
        SpringAnimation {
            spring: Motion.springStiffness
            damping: Motion.springDamping
            epsilon: Motion.springEpsilon
        }
    }

    Behavior on height {
        SpringAnimation {
            spring: Motion.springStiffness
            damping: Motion.springDamping
            epsilon: Motion.springEpsilon
        }
    }

    Behavior on radius {
        SpringAnimation {
            spring: Motion.springStiffness
            damping: Motion.springDamping
            epsilon: Motion.springEpsilon
        }
    }

    RowLayout {
        id: leftGroup
        width: implicitWidth
        height: 32
        spacing: 0
        x: root.isExpanded ? (-leftGroup.width - 20) : root.collapsedLeftX
        y: 0
        opacity: root.isExpanded ? 0.0 : 1.0
        scale: root.isExpanded ? 0.8 : 1.0
        visible: opacity > 0

        Behavior on x {
            enabled: root.isExpanded || root.menuTransitioning
            SpringAnimation {
                spring: Motion.springStiffness
                damping: Motion.springDamping
                epsilon: Motion.springEpsilon
            }
        }
        Behavior on opacity {
            NumberAnimation { duration: root.isExpanded ? 200 : 260; easing.type: Motion.easingStandard }
        }
        Behavior on scale {
            SpringAnimation {
                spring: Motion.springStiffness
                damping: Motion.springDamping
                epsilon: Motion.springScaleEpsilon
            }
        }

        Audio {
            id: audioModule
            Layout.alignment: Qt.AlignVCenter
        }
    }

    RowLayout {
        id: batteryGroup
        width: implicitWidth
        height: 32
        spacing: 0
        x: root.isExpanded ? (root.expandedWidth + 20) : root.collapsedBatteryX
        y: 0
        opacity: root.isExpanded ? 0.0 : 1.0
        scale: root.isExpanded ? 0.8 : 1.0
        visible: opacity > 0

        Behavior on x {
            enabled: root.isExpanded || root.menuTransitioning
            SpringAnimation {
                spring: Motion.springStiffness
                damping: Motion.springDamping
                epsilon: Motion.springEpsilon
            }
        }
        Behavior on opacity {
            NumberAnimation { duration: root.isExpanded ? 200 : 260; easing.type: Motion.easingStandard }
        }
        Behavior on scale {
            SpringAnimation {
                spring: Motion.springStiffness
                damping: Motion.springDamping
                epsilon: Motion.springScaleEpsilon
            }
        }

        Battery {
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Item {
        id: headerBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 44

        Item {
            id: wifiHero
            width: 20
            height: 20
            x: root.isWifi 
                ? root.expandedHeroX 
                : (root.isBluetooth ? (-width - 20) : root.collapsedWifiX)
            y: root.isWifi ? ((headerBar.height - height) / 2) : ((32 - height) / 2)
            opacity: root.isBluetooth ? 0.0 : 1.0
            scale: root.isBluetooth ? 0.8 : 1.0
            visible: opacity > 0

            Behavior on x {
                enabled: root.isExpanded || root.menuTransitioning
                SpringAnimation {
                    spring: Motion.springStiffness
                    damping: Motion.springDamping
                    epsilon: Motion.springEpsilon
                }
            }
            Behavior on y {
                SpringAnimation {
                    spring: Motion.springStiffness
                    damping: Motion.springDamping
                    epsilon: Motion.springEpsilon
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: root.isExpanded ? 200 : 260; easing.type: Motion.easingStandard }
            }
            Behavior on scale {
                SpringAnimation {
                    spring: Motion.springStiffness
                    damping: Motion.springDamping
                    epsilon: Motion.springScaleEpsilon
                }
            }

            Icon {
                id: wifiHeroIcon
                anchors.centerIn: parent
                text: Network.iconName
                color: root.isWifi 
                    ? Colors.primary 
                    : (Network.connected 
                        ? (wifiHover.hovered ? Colors.on_surface : Colors.on_surface_variant) 
                        : Colors.error)

                Behavior on color {
                    ColorAnimation { duration: Motion.durationNormal }
                }
            }

            TapHandler {
                onTapped: {
                    if (root.currentMenu === "wifi") {
                        root.currentMenu = "";
                    } else {
                        root.currentMenu = "wifi";
                        if (Network.networks.length === 0) {
                            Network.scan(true);
                        }
                    }
                }
            }

            HoverHandler {
                id: wifiHover
                cursorShape: Qt.PointingHandCursor
            }
        }

        Item {
            id: btHero
            width: 20
            height: 20
            x: root.isBluetooth 
                ? root.expandedHeroX 
                : (root.isWifi ? (root.expandedWidth + 20) : root.collapsedBtX)
            y: root.isBluetooth ? ((headerBar.height - height) / 2) : ((32 - height) / 2)
            opacity: root.isWifi ? 0.0 : 1.0
            scale: root.isWifi ? 0.8 : 1.0
            visible: opacity > 0

            Behavior on x {
                enabled: root.isExpanded || root.menuTransitioning
                SpringAnimation {
                    spring: Motion.springStiffness
                    damping: Motion.springDamping
                    epsilon: Motion.springEpsilon
                }
            }
            Behavior on y {
                SpringAnimation {
                    spring: Motion.springStiffness
                    damping: Motion.springDamping
                    epsilon: Motion.springEpsilon
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: root.isExpanded ? 200 : 260; easing.type: Motion.easingStandard }
            }
            Behavior on scale {
                SpringAnimation {
                    spring: Motion.springStiffness
                    damping: Motion.springDamping
                    epsilon: Motion.springScaleEpsilon
                }
            }

            Icon {
                id: btHeroIcon
                anchors.centerIn: parent
                text: Bluetooth.iconName
                color: root.isBluetooth 
                    ? Colors.primary 
                    : (!Bluetooth.powered 
                        ? Colors.outline 
                        : (Bluetooth.connected 
                            ? (btHover.hovered ? Colors.on_surface : Colors.primary) 
                            : (btHover.hovered ? Colors.on_surface : Colors.on_surface_variant)))

                Behavior on color {
                    ColorAnimation { duration: Motion.durationNormal }
                }
            }

            TapHandler {
                onTapped: {
                    if (root.currentMenu === "bluetooth") {
                        root.currentMenu = "";
                    } else {
                        root.currentMenu = "bluetooth";
                        if (Bluetooth.devices.length === 0) {
                            Bluetooth.scan(true);
                        }
                    }
                }
            }

            HoverHandler {
                id: btHover
                cursorShape: Qt.PointingHandCursor
            }
        }

        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: 44
            anchors.right: headerActions.left
            anchors.rightMargin: 8
            anchors.verticalCenter: headerBar.verticalCenter
            spacing: Metrics.layoutSpacing
            opacity: root.isExpanded ? 1.0 : 0.0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: root.isExpanded ? 220 : 160; easing.type: Motion.easingStandard }
            }

            StyledText {
                text: root.isWifi ? "Wi-Fi" : "Bluetooth"
                font.pixelSize: Typography.sizeTitle
                font.weight: Typography.weightBold
            }

            StyledText {
                text: {
                    if (root.isWifi) {
                        return Network.scanning ? "• scanning..." : "";
                    } else {
                        if (Bluetooth.scanning) return "• scanning...";
                        if (!Bluetooth.powered) return "• Off";
                        return "";
                    }
                }
                color: (root.isWifi ? Network.scanning : Bluetooth.scanning) ? Colors.primary : Colors.outline
                font.pixelSize: Typography.sizeCaption
                font.weight: Typography.weightMedium
                visible: text.length > 0
                opacity: visible ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: Motion.durationNormal }
                }
            }
        }

        RowLayout {
            id: headerActions
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: headerBar.verticalCenter
            spacing: Metrics.itemSpacing
            opacity: root.isExpanded ? 1.0 : 0.0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: root.isExpanded ? 220 : 160; easing.type: Motion.easingStandard }
            }

            IconButton {
                visible: root.isBluetooth
                icon: Bluetooth.powered ? "power_settings_new" : "power_off"
                active: Bluetooth.powered
                onClicked: Bluetooth.togglePower()
            }

            IconButton {
                icon: "refresh"
                rotating: root.isWifi ? Network.scanning : Bluetooth.scanning
                active: root.isWifi ? Network.scanning : Bluetooth.scanning
                onClicked: {
                    if (root.isWifi) {
                        Network.scan(true);
                    } else {
                        Bluetooth.scan(true);
                    }
                }
            }

            IconButton {
                icon: "close"
                onClicked: root.currentMenu = ""
            }
        }
    }

    SquiggleDivider {
        id: squiggleDivider
        anchors.top: headerBar.bottom
        anchors.topMargin: Metrics.layoutSpacing
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Metrics.sidePadding
        anchors.rightMargin: Metrics.sidePadding
        active: root.isWifi ? Network.scanning : Bluetooth.scanning
        opacity: root.isExpanded ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: root.isExpanded ? 220 : 160; easing.type: Motion.easingStandard }
        }
    }

    Item {
        id: listContainer
        anchors.top: squiggleDivider.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: 14

        opacity: root.isExpanded ? ((root.isWifi ? Network.scanning : Bluetooth.scanning) ? 0.65 : 1.0) : 0.0
        visible: opacity > 0

        transform: Translate {
            y: root.isExpanded ? 0 : 10
            Behavior on y {
                SpringAnimation {
                    spring: Motion.springStiffness
                    damping: Motion.springDamping
                    epsilon: Motion.springEpsilon
                }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: root.isExpanded ? 240 : 160; easing.type: Motion.easingStandard }
        }

        WifiMenu {
            visible: root.isWifi
        }

        BluetoothMenu {
            visible: root.isBluetooth
        }
    }
}
