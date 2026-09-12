import QtQuick
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    anchors.fill: parent

    readonly property bool listEmpty: !Bluetooth.powered || bluetoothList.count === 0

    EmptyState {
        anchors.centerIn: parent
        opacity: root.listEmpty ? 1.0 : 0.0
        visible: opacity > 0
        icon: !Bluetooth.powered ? "bluetooth_disabled" : (Bluetooth.scanning ? "sync" : "bluetooth_searching")
        rotating: Bluetooth.scanning && Bluetooth.powered
        text: !Bluetooth.powered
            ? "Bluetooth is turned off"
            : (Bluetooth.scanning ? "Searching devices..." : "No devices found")

        Behavior on opacity {
            FadeAnimation {
                entering: root.listEmpty
                stagger: Motion.contentStagger
            }
        }
    }

    ListView {
        id: bluetoothList
        anchors.fill: parent
        clip: true
        spacing: Metrics.layoutSpacing
        visible: Bluetooth.powered
        model: Bluetooth.powered ? Bluetooth.deviceModel : null
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
            required property string mac
            required property string name
            required property string deviceIcon
            required property bool connected
            required property bool paired
            required property int battery

            readonly property bool isBusy: Bluetooth.busyMac === mac

            width: bluetoothList.width
            active: connected
            loading: isBusy
            icon: deviceIcon
            title: name
            subtitle: {
                if (isBusy) return connected ? "Disconnecting..." : "Connecting...";
                if (connected) return battery >= 0 ? ("Connected • " + battery + "%") : "Connected";
                return paired ? "Paired" : "";
            }
            subtitleColor: isBusy ? Colors.tertiary : (connected ? Colors.primary : Colors.on_surface_variant)
            trailingText: (battery >= 0 && !connected) ? (battery + "%") : ""
            onClicked: {
                if (isBusy)
                    return;
                if (connected)
                    Bluetooth.disconnect(mac);
                else
                    Bluetooth.connect(mac);
            }
        }
    }
}
