import QtQuick
import qs.theme

Item {
    id: root

    property string icon: ""
    property color color: iconHover.hovered ? Colors.on_surface : Colors.on_surface_variant
    property color activeColor: Colors.primary
    property bool active: false
    property int pixelSize: Typography.sizeIconMedium
    property bool rotating: false
    property alias hovered: iconHover.hovered

    signal clicked()

    implicitWidth: pixelSize
    implicitHeight: pixelSize

    Text {
        id: iconText
        anchors.centerIn: parent
        text: root.icon
        color: root.active ? root.activeColor : root.color
        font.family: Typography.iconFamily
        font.pixelSize: root.pixelSize

        Behavior on color {
            ColorAnimation { duration: Motion.durationNormal }
        }

        RotationAnimator on rotation {
            running: root.rotating
            from: 0
            to: 360
            loops: Animation.Infinite
            duration: Motion.durationSpin
        }
    }

    TapHandler {
        onTapped: root.clicked()
    }

    HoverHandler {
        id: iconHover
        cursorShape: Qt.PointingHandCursor
    }
}
