import QtQuick
import qs.theme
import qs.components

Item {
    id: root

    property date date: new Date()
    property real clockSize: 180
    property real exit: 0

    readonly property var axes: ({ "wght": 600, "wdth": 25, "ROND": 0 })
    readonly property real padding: 0
    readonly property real gap: clockSize * 0.07
    readonly property real innerHeight: clockSize * 1.2
    readonly property real inkRatio: unitMetrics.tightBoundingRect.height > 0 ? unitMetrics.tightBoundingRect.height / 100 : 0.7
    readonly property real hoursSize: innerHeight / inkRatio
    readonly property real minutesSize: hoursSize * 0.46
    readonly property real hoursSlot: hoursSlotMetrics.tightBoundingRect.width
    readonly property real columnWidth: Math.max(minutesSlotMetrics.tightBoundingRect.width, clockSize * 0.42)
    readonly property real minutesInkHeight: innerHeight * 0.46
    readonly property real split: exit * clockSize * 0.9
    readonly property point clockCenter: Qt.point(width / 2, height / 2)

    implicitWidth: padding * 2 + hoursSlot + gap + columnWidth
    implicitHeight: padding * 2 + innerHeight

    TextMetrics {
        id: unitMetrics
        font.family: Typography.family
        font.pixelSize: 100
        font.variableAxes: root.axes
        text: "0"
    }

    TextMetrics {
        id: hoursSlotMetrics
        font: hoursText.font
        text: "00"
    }

    TextMetrics {
        id: minutesSlotMetrics
        font: minutesText.font
        text: "00"
    }

    Item {
        x: root.padding
        y: root.padding
        width: root.hoursSlot
        height: root.innerHeight
        transform: Translate { x: -root.split }

        TextMetrics {
            id: hoursMetrics
            font: hoursText.font
            text: hoursText.text
        }

        Text {
            id: hoursText
            x: parent.width / 2 - hoursMetrics.tightBoundingRect.x - hoursMetrics.tightBoundingRect.width / 2
            y: parent.height / 2 - baselineOffset - hoursMetrics.tightBoundingRect.y - hoursMetrics.tightBoundingRect.height / 2
            text: Qt.formatDateTime(root.date, "hh")
            color: Colors.primary
            font.family: Typography.family
            font.pixelSize: root.hoursSize
            font.variableAxes: root.axes
            renderType: Text.CurveRendering
        }
    }

    Item {
        x: root.padding + root.hoursSlot + root.gap
        y: root.padding
        width: root.columnWidth
        height: root.innerHeight
        transform: Translate { x: root.split }

        TextMetrics {
            id: minutesMetrics
            font: minutesText.font
            text: minutesText.text
        }

        Text {
            id: minutesText
            x: parent.width / 2 - minutesMetrics.tightBoundingRect.x - minutesMetrics.tightBoundingRect.width / 2
            y: -baselineOffset - minutesMetrics.tightBoundingRect.y
            text: Qt.formatDateTime(root.date, "mm")
            color: Colors.tertiary
            font.family: Typography.family
            font.pixelSize: root.minutesSize
            font.variableAxes: root.axes
            renderType: Text.CurveRendering
        }

        Rectangle {
            id: badge
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: parent.height - root.minutesInkHeight - root.gap
            radius: Math.min(width, height) * 0.32
            color: Colors.primary_container

            Column {
                anchors.centerIn: parent
                spacing: -root.clockSize * 0.02

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(root.date, "ddd")
                    color: Colors.on_primary_container
                    font.pixelSize: Math.round(root.clockSize * 0.1)
                    font.weight: Typography.weightMedium
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(root.date, "d")
                    color: Colors.on_primary_container
                    font.pixelSize: Math.round(root.clockSize * 0.2)
                    font.weight: Font.Bold
                }
            }
        }
    }
}
