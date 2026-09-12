import QtQuick
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    anchors.fill: parent

    EmptyState {
        anchors.centerIn: parent
        opacity: wifiList.count === 0 ? 1.0 : 0.0
        visible: opacity > 0
        icon: Network.scanning ? "sync" : "wifi_off"
        rotating: Network.scanning
        text: Network.scanning ? "Searching networks..." : "No networks found"

        Behavior on opacity {
            FadeAnimation {
                entering: wifiList.count === 0
                stagger: Motion.contentStagger
            }
        }
    }

    ListView {
        id: wifiList
        anchors.fill: parent
        clip: true
        spacing: Metrics.layoutSpacing
        model: Network.networkModel
        boundsBehavior: Flickable.StopAtBounds

        add: Transition {
            NumberAnimation {
                properties: "opacity"
                from: 0.0
                to: 1.0
                duration: Motion.contentEnter
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.emphasizedDecelerate
            }
            NumberAnimation {
                properties: "scale"
                from: 0.92
                to: 1.0
                duration: Motion.contentEnter
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.emphasizedDecelerate
            }
        }

        remove: Transition {
            NumberAnimation {
                properties: "opacity"
                to: 0.0
                duration: Motion.contentExit
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.emphasizedAccelerate
            }
            NumberAnimation {
                properties: "scale"
                to: 0.92
                duration: Motion.contentExit
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.emphasizedAccelerate
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: Motion.durationMedium2
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.emphasized
            }
        }

        delegate: DeviceListItem {
            required property string ssid
            required property int strength
            required property bool inUse
            required property bool locked

            readonly property bool isConnecting: Network.connectingTo === ssid
            readonly property bool hasFailed: Network.failedSsid === ssid

            width: wifiList.width
            active: inUse
            loading: isConnecting
            icon: {
                if (strength >= 67) return "wifi";
                if (strength >= 34) return "wifi_2_bar";
                return "wifi_1_bar";
            }
            title: ssid
            subtitle: {
                if (isConnecting) return "Connecting...";
                if (hasFailed) return "Connection failed";
                return inUse ? "Connected" : "";
            }
            subtitleColor: hasFailed ? Colors.error : (isConnecting ? Colors.tertiary : (inUse ? Colors.primary : Colors.on_surface_variant))
            trailingIcon: locked ? "lock" : ""
            onClicked: {
                if (!inUse && !isConnecting)
                    Network.connect(ssid);
            }
        }
    }
}
