import QtQuick
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    anchors.fill: parent

    EmptyState {
        anchors.centerIn: parent
        visible: !Bluetooth.powered || bluetoothList.count === 0
        icon: !Bluetooth.powered ? "bluetooth_disabled" : (Bluetooth.scanning ? "sync" : "bluetooth_searching")
        rotating: Bluetooth.scanning && Bluetooth.powered
        text: !Bluetooth.powered 
            ? "Bluetooth is turned off" 
            : (Bluetooth.scanning ? "Searching devices..." : "No devices found")
    }

    ListView {
        id: bluetoothList
        anchors.fill: parent
        clip: true
        spacing: Metrics.layoutSpacing
        visible: Bluetooth.powered
        model: Bluetooth.powered ? Bluetooth.devices : []

        delegate: DeviceListItem {
            width: bluetoothList.width
            active: modelData.connected
            icon: modelData.icon || "bluetooth"
            title: modelData.name
            subtitle: {
                if (modelData.connected) {
                    return modelData.battery >= 0 ? ("Connected • " + modelData.battery + "%") : "Connected";
                }
                return modelData.paired ? "Paired" : "";
            }
            trailingText: (modelData.battery >= 0 && !modelData.connected) ? (modelData.battery + "%") : ""
            onClicked: {
                if (modelData.connected) {
                    Bluetooth.disconnect(modelData.mac);
                } else {
                    Bluetooth.connect(modelData.mac);
                }
            }
        }
    }
}
