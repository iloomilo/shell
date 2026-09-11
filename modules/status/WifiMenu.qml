import QtQuick
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    anchors.fill: parent

    EmptyState {
        anchors.centerIn: parent
        visible: wifiList.count === 0
        icon: Network.scanning ? "sync" : "wifi_off"
        rotating: Network.scanning
        text: Network.scanning ? "Searching networks..." : "No networks found"
    }

    ListView {
        id: wifiList
        anchors.fill: parent
        clip: true
        spacing: Metrics.layoutSpacing
        model: Network.networks

        delegate: DeviceListItem {
            width: wifiList.width
            active: modelData.inUse
            icon: {
                if (modelData.signal >= 75) return "wifi";
                if (modelData.signal >= 50) return "wifi_2_bar";
                return "wifi_1_bar";
            }
            title: modelData.ssid
            subtitle: modelData.inUse ? "Connected" : ""
            trailingIcon: modelData.locked ? "lock" : ""
            onClicked: {
                if (!modelData.inUse) {
                    Network.connect(modelData.ssid);
                }
            }
        }
    }
}
