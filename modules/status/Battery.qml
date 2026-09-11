import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.theme
import qs.components

Rectangle {
    id: root

    readonly property var device: UPower.displayDevice
    visible: Boolean(device && device.isPresent)

    readonly property int percent: device 
        ? Math.round(device.percentage <= 1.0 ? device.percentage * 100 : device.percentage) 
        : 0

    readonly property bool isCharging: Boolean(device && (
        device.state === UPowerDeviceState.Charging || 
        device.state === UPowerDeviceState.PendingCharge
    ))

    readonly property bool isLow: percent <= 20 && !isCharging

    readonly property string iconName: {
        if (isCharging) return "battery_charging_full";
        if (percent >= 90) return "battery_full";
        if (percent >= 70) return "battery_6_bar";
        if (percent >= 50) return "battery_4_bar";
        if (percent >= 25) return "battery_2_bar";
        if (percent >= 10) return "battery_1_bar";
        return "battery_alert";
    }

    height: 24
    width: content.implicitWidth + 14
    implicitWidth: width
    implicitHeight: height
    radius: 12
    color: isLow ? Colors.error_container : Colors.surface_container_high

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 4

        Icon {
            text: root.iconName
            color: root.isLow ? Colors.error : (root.isCharging ? Colors.primary : Colors.on_surface_variant)
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            text: root.percent + "%"
            color: root.isLow ? Colors.on_error_container : Colors.on_surface
            font.pixelSize: 11
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
