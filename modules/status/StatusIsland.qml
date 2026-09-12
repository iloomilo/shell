import QtQuick
import QtQuick.Layouts
import qs.services
import qs.theme
import qs.components

Rectangle {
    id: root

    property string currentMenu: ""
    property string lastMenu: "audio"

    readonly property bool isExpanded: currentMenu !== ""
    readonly property bool isAudio: currentMenu === "audio"
    readonly property bool isWifi: currentMenu === "wifi"
    readonly property bool isBluetooth: currentMenu === "bluetooth"
    readonly property bool isPower: currentMenu === "power"

    readonly property string displayMenu: currentMenu !== "" ? currentMenu : lastMenu
    readonly property bool showsAudio: displayMenu === "audio"
    readonly property bool showsWifi: displayMenu === "wifi"
    readonly property bool showsBluetooth: displayMenu === "bluetooth"
    readonly property bool showsPower: displayMenu === "power"

    onCurrentMenuChanged: {
        if (currentMenu !== "")
            lastMenu = currentMenu;
        Power.menuOpen = (currentMenu === "power");
    }

    Connections {
        target: Power
        function onMenuOpenChanged() {
            if (Power.menuOpen && root.currentMenu !== "power") {
                root.currentMenu = "power";
            } else if (!Power.menuOpen && root.currentMenu === "power") {
                root.currentMenu = "";
            }
        }
    }

    property bool expandedVisible: false
    property bool collapsedVisible: true

    onIsExpandedChanged: {
        menuTransitioning = true;
        menuTransitionTimer.restart();

        if (isExpanded) {
            collapsedVisible = false;
            contentDelay.interval = Motion.contentStagger;
        } else {
            expandedVisible = false;
            contentDelay.interval = Motion.collapseStagger;
        }
        contentDelay.restart();
    }

    Timer {
        id: contentDelay
        repeat: false
        onTriggered: {
            if (root.isExpanded)
                root.expandedVisible = true;
            else
                root.collapsedVisible = true;
        }
    }
    property bool menuTransitioning: false

    Timer {
        id: menuTransitionTimer
        interval: 400
        repeat: false
        onTriggered: root.menuTransitioning = false
    }

    readonly property real itemSpacing: Metrics.itemSpacing
    readonly property real sidePadding: Metrics.sidePadding
    readonly property real collapsedAudioX: sidePadding
    readonly property real collapsedWifiX: collapsedAudioX + audioHero.width + itemSpacing
    readonly property real collapsedBtX: collapsedWifiX + wifiHero.width + itemSpacing
    readonly property real collapsedBatteryX: collapsedBtX + btHero.width + itemSpacing
    readonly property real collapsedPowerX: collapsedBatteryX + batteryGroup.width + itemSpacing + 8
    readonly property real collapsedWidth: collapsedPowerX + 20 + sidePadding

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
        MorphAnimation { expanding: root.isExpanded }
    }

    Behavior on height {
        MorphAnimation { expanding: root.isExpanded }
    }

    Behavior on radius {
        MorphAnimation { expanding: root.isExpanded }
    }

    RowLayout {
        id: batteryGroup
        width: implicitWidth
        height: Metrics.islandHeight
        spacing: 0
        x: root.isExpanded ? (root.expandedWidth + 20) : root.collapsedBatteryX
        y: 0
        opacity: root.collapsedVisible ? 1.0 : 0.0
        scale: root.isExpanded ? 0.8 : 1.0
        visible: opacity > 0

        Behavior on x {
            enabled: root.isExpanded || root.menuTransitioning
            MorphAnimation { expanding: root.isExpanded }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Motion.contentFade
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.standard
            }
        }
        Behavior on scale {
            MorphAnimation { expanding: root.isExpanded }
        }

        Battery {
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Item {
        id: headerBar
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.expandedWidth
        height: Metrics.barHeight

        // Audio Hero Icon
        Item {
            id: audioHero
            width: 20
            height: 20
            x: root.isAudio 
                ? root.expandedHeroX 
                : ((root.isWifi || root.isBluetooth || root.isPower) ? (-width - 20) : root.collapsedAudioX)
            y: root.isAudio ? ((headerBar.height - height) / 2) : ((Metrics.islandHeight - height) / 2)
            opacity: (root.isWifi || root.isBluetooth || root.isPower) ? 0.0 : 1.0
            scale: (root.isWifi || root.isBluetooth || root.isPower) ? 0.8 : 1.0
            visible: opacity > 0

            Behavior on x {
                enabled: root.isExpanded || root.menuTransitioning
                MorphAnimation { expanding: root.isExpanded }
            }
            Behavior on y {
                MorphAnimation { expanding: root.isExpanded }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.contentFade
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.standard
                }
            }
            Behavior on scale {
                MorphAnimation { expanding: root.isExpanded }
            }

            Icon {
                id: audioHeroIcon
                anchors.centerIn: parent
                text: AudioService.iconName
                color: root.isAudio 
                    ? Colors.primary 
                    : (AudioService.muted 
                        ? Colors.error 
                        : (audioHover.hovered ? Colors.on_surface : Colors.on_surface_variant))

                Behavior on color {
                    ColorAnimation { duration: Motion.durationNormal }
                }
            }

            TapHandler {
                onTapped: {
                    if (root.currentMenu === "audio") {
                        root.currentMenu = "";
                    } else {
                        root.currentMenu = "audio";
                    }
                }
            }

            WheelHandler {
                orientation: Qt.Vertical
                onWheel: event => {
                    let step = (event.angleDelta.y > 0 ? 0.05 : -0.05);
                    AudioService.setVolume(AudioService.volume + step, root.isExpanded);
                }
            }

            HoverHandler {
                id: audioHover
                cursorShape: Qt.PointingHandCursor
            }
        }

        // Wi-Fi Hero Icon
        Item {
            id: wifiHero
            width: 20
            height: 20
            x: root.isWifi 
                ? root.expandedHeroX 
                : (root.isBluetooth || root.isPower ? (-width - 20) : (root.isAudio ? (root.expandedWidth + 20) : root.collapsedWifiX))
            y: root.isWifi ? ((headerBar.height - height) / 2) : ((Metrics.islandHeight - height) / 2)
            opacity: (root.isAudio || root.isBluetooth || root.isPower) ? 0.0 : 1.0
            scale: (root.isAudio || root.isBluetooth || root.isPower) ? 0.8 : 1.0
            visible: opacity > 0

            Behavior on x {
                enabled: root.isExpanded || root.menuTransitioning
                MorphAnimation { expanding: root.isExpanded }
            }
            Behavior on y {
                MorphAnimation { expanding: root.isExpanded }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.contentFade
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.standard
                }
            }
            Behavior on scale {
                MorphAnimation { expanding: root.isExpanded }
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

        // Bluetooth Hero Icon
        Item {
            id: btHero
            width: 20
            height: 20
            x: root.isBluetooth 
                ? root.expandedHeroX 
                : (root.isPower ? (-width - 20) : (root.isAudio || root.isWifi ? (root.expandedWidth + 20) : root.collapsedBtX))
            y: root.isBluetooth ? ((headerBar.height - height) / 2) : ((Metrics.islandHeight - height) / 2)
            opacity: (root.isAudio || root.isWifi || root.isPower) ? 0.0 : 1.0
            scale: (root.isAudio || root.isWifi || root.isPower) ? 0.8 : 1.0
            visible: opacity > 0

            Behavior on x {
                enabled: root.isExpanded || root.menuTransitioning
                MorphAnimation { expanding: root.isExpanded }
            }
            Behavior on y {
                MorphAnimation { expanding: root.isExpanded }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.contentFade
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.standard
                }
            }
            Behavior on scale {
                MorphAnimation { expanding: root.isExpanded }
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

        // Power Hero Icon
        Item {
            id: powerHero
            width: 20
            height: 20
            x: root.isPower 
                ? root.expandedHeroX 
                : (root.isAudio || root.isWifi || root.isBluetooth ? (root.expandedWidth + 20) : root.collapsedPowerX)
            y: root.isPower ? ((headerBar.height - height) / 2) : ((Metrics.islandHeight - height) / 2)
            opacity: (root.isAudio || root.isWifi || root.isBluetooth) ? 0.0 : 1.0
            scale: (root.isAudio || root.isWifi || root.isBluetooth) ? 0.8 : 1.0
            visible: opacity > 0

            Behavior on x {
                enabled: root.isExpanded || root.menuTransitioning
                MorphAnimation { expanding: root.isExpanded }
            }
            Behavior on y {
                MorphAnimation { expanding: root.isExpanded }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.contentFade
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.standard
                }
            }
            Behavior on scale {
                MorphAnimation { expanding: root.isExpanded }
            }

            Icon {
                id: powerHeroIcon
                anchors.centerIn: parent
                text: "power_settings_new"
                color: root.isPower 
                    ? Colors.error 
                    : (powerHover.hovered ? Colors.error : Colors.on_surface_variant)

                Behavior on color {
                    ColorAnimation { duration: Motion.durationNormal }
                }
            }

            TapHandler {
                onTapped: {
                    if (root.currentMenu === "power") {
                        root.currentMenu = "";
                    } else {
                        root.currentMenu = "power";
                    }
                }
            }

            HoverHandler {
                id: powerHover
                cursorShape: Qt.PointingHandCursor
            }
        }

        StyledText {
            anchors.left: parent.left
            anchors.leftMargin: Metrics.barHeight
            anchors.right: headerActions.left
            anchors.rightMargin: 8
            anchors.verticalCenter: headerBar.verticalCenter
            text: root.showsPower ? "Power" : (root.showsAudio ? "Audio" : (root.showsWifi ? "Wi-Fi" : "Bluetooth"))
            font.pixelSize: Typography.sizeTitle
            font.weight: Typography.weightBold
            elide: Text.ElideRight
            opacity: root.expandedVisible ? 1.0 : 0.0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.contentFade
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.standard
                }
            }
        }

        RowLayout {
            id: headerActions
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: headerBar.verticalCenter
            spacing: Metrics.layoutSpacing
            opacity: root.expandedVisible ? 1.0 : 0.0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.contentFade
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.standard
                }
            }

            IconButton {
                visible: root.showsAudio
                icon: AudioService.muted ? "volume_off" : "volume_up"
                active: !AudioService.muted
                onClicked: AudioService.toggleMute()
            }

            IconButton {
                visible: root.showsBluetooth
                icon: Bluetooth.powered ? "power_settings_new" : "power_off"
                active: Bluetooth.powered
                onClicked: Bluetooth.togglePower()
            }

            IconButton {
                visible: root.showsWifi || root.showsBluetooth
                icon: "refresh"
                rotating: root.showsWifi ? Network.scanning : Bluetooth.scanning
                active: root.showsWifi ? Network.scanning : Bluetooth.scanning
                activeColor: Colors.tertiary
                onClicked: {
                    if (root.showsWifi) {
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
        anchors.leftMargin: Metrics.sidePadding
        width: root.expandedWidth - 2 * Metrics.sidePadding
        active: (root.showsWifi && Network.scanning) || (root.showsBluetooth && Bluetooth.scanning)
        opacity: root.expandedVisible ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.contentFade
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.standard
            }
        }
    }

    Item {
        id: listContainer
        anchors.top: squiggleDivider.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.leftMargin: 10
        width: root.expandedWidth - 20
        height: root.expandedHeight - y - 14

        opacity: root.expandedVisible ? ((root.showsWifi ? Network.scanning : Bluetooth.scanning) ? 0.65 : 1.0) : 0.0
        visible: opacity > 0

        transform: Translate {
            y: root.isExpanded ? 0 : 10
            Behavior on y {
                MorphAnimation { expanding: root.isExpanded }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.contentFade
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.standard
            }
        }

        AudioMenu {
            visible: root.showsAudio
        }

        WifiMenu {
            visible: root.showsWifi
        }

        BluetoothMenu {
            visible: root.showsBluetooth
        }

        PowerMenu {
            visible: root.showsPower
            onActionTriggered: root.currentMenu = ""
        }
    }
}
