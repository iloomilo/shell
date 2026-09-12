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
    property int touchTarget: 32

    signal clicked()

    implicitWidth: touchTarget
    implicitHeight: touchTarget

    Rectangle {
        id: stateLayer
        anchors.centerIn: parent
        width: root.touchTarget
        height: root.touchTarget
        radius: width / 2
        color: root.active ? root.activeColor : Colors.on_surface
        opacity: tapHandler.pressed ? 0.12 : (iconHover.hovered ? 0.08 : 0.0)

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationShort2
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.standard
            }
        }
    }

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
        id: tapHandler
        onTapped: root.clicked()
    }

    HoverHandler {
        id: iconHover
        cursorShape: Qt.PointingHandCursor
    }
}
