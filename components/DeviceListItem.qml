import QtQuick
import QtQuick.Layouts
import qs.theme

Rectangle {
    id: root

    property bool active: false
    property bool loading: false
    property bool danger: false
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string trailingIcon: ""
    property string trailingText: ""
    property bool showCheckmark: active
    property color subtitleColor: active ? Colors.primary : Colors.on_surface_variant

    signal clicked()

    readonly property color stateColor: danger ? Colors.error : (active ? Colors.on_primary_container : Colors.on_surface)

    height: active ? Metrics.itemHeightActive : Metrics.itemHeightNormal
    radius: Metrics.radiusCard
    color: active ? Colors.primary_container : (danger && itemHover.hovered ? Colors.error_container : "transparent")
    clip: true

    Behavior on color {
        ColorAnimation { duration: Motion.durationNormal }
    }

    Behavior on height {
        NumberAnimation {
            duration: Motion.durationShort4
            easing.type: Easing.Bezier
            easing.bezierCurve: Motion.emphasized
        }
    }

    Rectangle {
        id: stateLayer
        anchors.fill: parent
        radius: parent.radius
        color: root.stateColor
        opacity: tapHandler.pressed ? 0.12 : (itemHover.hovered ? 0.08 : 0.0)

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationShort2
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.standard
            }
        }
    }

    Rectangle {
        id: ripple

        property real cx: 0
        property real cy: 0
        readonly property real maxSize: Math.max(root.width, root.height) * 2.2

        width: 0
        height: width
        radius: width / 2
        x: cx - width / 2
        y: cy - height / 2
        color: root.stateColor
        opacity: 0
    }

    ParallelAnimation {
        id: rippleAnim

        NumberAnimation {
            target: ripple
            property: "width"
            from: 0
            to: ripple.maxSize
            duration: Motion.durationMedium2
            easing.type: Easing.Bezier
            easing.bezierCurve: Motion.standardDecelerate
        }

        SequentialAnimation {
            NumberAnimation {
                target: ripple
                property: "opacity"
                from: 0.0
                to: 0.12
                duration: Motion.durationShort2
            }
            NumberAnimation {
                target: ripple
                property: "opacity"
                to: 0.0
                duration: Motion.durationMedium1
            }
        }
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
                : (root.danger
                    ? (itemHover.hovered ? Colors.error : Colors.error_container)
                    : (itemHover.hovered ? Colors.surface_container_highest : Colors.surface_container_high))
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation { duration: Motion.durationNormal }
            }

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.active
                    ? Colors.on_primary
                    : (root.danger
                        ? (itemHover.hovered ? Colors.on_error : Colors.error)
                        : Colors.on_surface)
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
                color: root.active
                    ? Colors.on_primary_container
                    : (root.danger
                        ? (itemHover.hovered ? Colors.on_error_container : Colors.error)
                        : Colors.on_surface)
                font.family: Typography.family
                font.pixelSize: Typography.sizeBody
                font.weight: root.active ? Typography.weightBold : Typography.weightNormal
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: root.subtitle.length > 0
                text: root.subtitle
                color: root.subtitleColor
                font.family: Typography.family
                font.pixelSize: Typography.sizeSmall
                font.weight: root.active ? Typography.weightMedium : Typography.weightNormal
            }
        }

        Text {
            visible: root.trailingText.length > 0 && !root.loading
            text: root.trailingText
            color: Colors.on_surface_variant
            font.family: Typography.family
            font.pixelSize: Typography.sizeCaption
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: root.trailingIcon.length > 0 && !root.loading
            text: root.trailingIcon
            color: root.active ? Colors.on_primary_container : Colors.on_surface_variant
            font.family: Typography.iconFamily
            font.pixelSize: Typography.sizeIconSmall
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: root.showCheckmark && !root.loading
            text: "check_circle"
            color: Colors.primary
            font.family: Typography.iconFamily
            font.pixelSize: 16
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: root.loading
            text: "progress_activity"
            color: Colors.tertiary
            font.family: Typography.iconFamily
            font.pixelSize: 16
            Layout.alignment: Qt.AlignVCenter

            RotationAnimator on rotation {
                running: root.loading
                from: 0
                to: 360
                loops: Animation.Infinite
                duration: Motion.durationSpin
            }
        }
    }

    TapHandler {
        id: tapHandler
        onPressedChanged: {
            if (pressed) {
                ripple.cx = point.position.x;
                ripple.cy = point.position.y;
                rippleAnim.restart();
            }
        }
        onTapped: root.clicked()
    }

    HoverHandler {
        id: itemHover
        cursorShape: Qt.PointingHandCursor
    }
}
