import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.theme
import qs.components

RowLayout {
    id: root
    spacing: 4

    readonly property var device: UPower.displayDevice
    visible: Boolean(device && device.isPresent)

    readonly property int percent: device
        ? Math.round(device.percentage <= 1.0 ? device.percentage * 100 : device.percentage)
        : 0

    readonly property bool isCharging: Boolean(device && (
        device.state === UPowerDeviceState.Charging ||
        device.state === UPowerDeviceState.PendingCharge
    ))

    readonly property bool isFull: Boolean(device && device.state === UPowerDeviceState.FullyCharged)
    readonly property bool isLow: percent <= 20 && !isCharging

    property bool showTooltip: false
    property bool tooltipOpen: false

    readonly property string iconName: {
        if (isCharging) return "battery_charging_full";
        if (percent >= 90) return "battery_full";
        if (percent >= 70) return "battery_6_bar";
        if (percent >= 50) return "battery_4_bar";
        if (percent >= 25) return "battery_2_bar";
        if (percent >= 10) return "battery_1_bar";
        return "battery_alert";
    }

    function formatDuration(seconds) {
        if (!seconds || seconds <= 0 || isNaN(seconds))
            return "";
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        if (h > 0)
            return h + " h " + m + " min";
        return m + " min";
    }

    readonly property string statusText: {
        if (isFull)
            return "Fully charged";
        if (isCharging) {
            const t = formatDuration(device ? device.timeToFull : 0);
            return t.length > 0 ? t + " until full" : "Charging";
        }
        const t = formatDuration(device ? device.timeToEmpty : 0);
        return t.length > 0 ? t + " remaining" : "On battery";
    }

    Icon {
        id: batteryIcon
        text: root.iconName
        color: root.isLow ? Colors.error : (root.isCharging ? Colors.tertiary : (hover.hovered ? Colors.on_surface : Colors.on_surface_variant))
        Layout.alignment: Qt.AlignVCenter

        Behavior on color {
            ColorAnimation { duration: Motion.durationNormal }
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hovered) {
                tooltipHide.stop();
                tooltipDelay.restart();
            } else {
                tooltipDelay.stop();
                root.tooltipOpen = false;
                if (root.showTooltip)
                    tooltipHide.restart();
            }
        }
    }

    Timer {
        id: tooltipDelay
        interval: 350
        repeat: false
        onTriggered: {
            root.showTooltip = true;
            root.tooltipOpen = true;
        }
    }

    Timer {
        id: tooltipHide
        interval: Motion.durationShort4
        repeat: false
        onTriggered: root.showTooltip = false
    }

    PopupWindow {
        id: tooltip
        visible: root.showTooltip
        color: "transparent"
        implicitWidth: tooltipCard.implicitWidth
        implicitHeight: tooltipCard.implicitHeight

        anchor.item: batteryIcon
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 10

        Rectangle {
            id: tooltipCard
            implicitWidth: tooltipContent.implicitWidth + 24
            implicitHeight: tooltipContent.implicitHeight + 16
            radius: Metrics.radiusContainer
            color: Colors.surface_container_lowest

            transformOrigin: Item.Top
            opacity: root.tooltipOpen ? 1.0 : 0.0
            scale: root.tooltipOpen ? 1.0 : 0.88

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.durationShort3
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.emphasized
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Motion.durationShort4
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.emphasized
                }
            }

            ColumnLayout {
                id: tooltipContent
                anchors.centerIn: parent
                spacing: 2

                StyledText {
                    text: root.percent + "%"
                    color: root.isLow ? Colors.error : (root.isCharging ? Colors.tertiary : Colors.on_surface)
                    font.pixelSize: Typography.sizeTitle
                    font.weight: Typography.weightBold
                    Layout.alignment: Qt.AlignHCenter
                }

                StyledText {
                    text: root.statusText
                    color: Colors.on_surface_variant
                    font.pixelSize: Typography.sizeCaption
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
