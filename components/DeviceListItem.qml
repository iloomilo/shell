import QtQuick
import QtQuick.Layouts
import qs.theme

Rectangle {
    id: root

    property bool active: false
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string trailingIcon: ""
    property string trailingText: ""
    property bool showCheckmark: active

    signal clicked()

    height: active ? Metrics.itemHeightActive : Metrics.itemHeightNormal
    radius: Metrics.radiusCard
    color: active 
        ? Colors.primary_container 
        : (itemHover.hovered ? Colors.surface_container_high : "transparent")
    scale: tapHandler.pressed ? 0.98 : 1.0

    Behavior on color {
        ColorAnimation { duration: Motion.durationNormal }
    }

    Behavior on scale {
        NumberAnimation { duration: Motion.durationFast; easing.type: Motion.easingTactile }
    }

    Behavior on height {
        NumberAnimation { duration: Motion.durationSlow; easing.type: Motion.easingTactile }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 10
        spacing: Metrics.itemSpacing

        Rectangle {
            width: Metrics.avatarSize
            height: Metrics.avatarSize
            radius: Metrics.avatarSize / 2
            color: root.active 
                ? Colors.primary 
                : (itemHover.hovered ? Colors.surface_container_highest : Colors.surface_container)
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation { duration: Motion.durationNormal }
            }

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.active ? Colors.on_primary : Colors.on_surface
                font.family: Typography.iconFamily
                font.pixelSize: 15
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                text: root.title
                color: root.active ? Colors.on_primary_container : Colors.on_surface
                font.family: Typography.family
                font.pixelSize: Typography.sizeBody
                font.weight: root.active ? Typography.weightBold : Typography.weightNormal
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: root.subtitle.length > 0
                text: root.subtitle
                color: root.active ? Colors.primary : Colors.on_surface_variant
                font.family: Typography.family
                font.pixelSize: Typography.sizeSmall
                font.weight: root.active ? Typography.weightMedium : Typography.weightNormal
            }
        }

        Text {
            visible: root.trailingText.length > 0
            text: root.trailingText
            color: Colors.on_surface_variant
            font.family: Typography.family
            font.pixelSize: Typography.sizeCaption
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: root.trailingIcon.length > 0
            text: root.trailingIcon
            color: root.active ? Colors.on_primary_container : Colors.on_surface_variant
            font.family: Typography.iconFamily
            font.pixelSize: Typography.sizeIconSmall
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: root.showCheckmark
            text: "check_circle"
            color: Colors.primary
            font.family: Typography.iconFamily
            font.pixelSize: 16
            Layout.alignment: Qt.AlignVCenter
        }
    }

    TapHandler {
        id: tapHandler
        onTapped: root.clicked()
    }

    HoverHandler {
        id: itemHover
        cursorShape: Qt.PointingHandCursor
    }
}
