import QtQuick
import qs.theme

Item {
    id: root

    property real value: 0.0
    property real from: 0.0
    property real to: 1.0
    property real stepSize: 0.01
    property bool enabled: true

    property color activeColor: Colors.primary
    property color inactiveColor: Colors.surface_container_highest
    property color thumbColor: activeColor

    property real trackHeight: 16
    property real thumbWidth: 6
    property real thumbHeight: 28
    property real thumbPressedHeight: 34
    property real gap: 4

    signal moved(real value)

    readonly property real normalizedValue: {
        if (to === from) return 0;
        return Math.max(0.0, Math.min(1.0, (value - from) / (to - from)));
    }

    readonly property bool isPressed: mouseArea.pressed
    readonly property bool isHovered: mouseArea.containsMouse

    implicitWidth: 160
    implicitHeight: 40

    // Full interactive MouseArea
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: root.enabled
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function updateValue(mouseX) {
            let availableWidth = root.width - root.thumbWidth;
            if (availableWidth <= 0) return;
            let relativeX = Math.max(0, Math.min(availableWidth, mouseX - (root.thumbWidth / 2)));
            let ratio = relativeX / availableWidth;
            let rawValue = root.from + ratio * (root.to - root.from);
            if (root.stepSize > 0) {
                rawValue = Math.round(rawValue / root.stepSize) * root.stepSize;
            }
            let clamped = Math.max(root.from, Math.min(root.to, rawValue));
            root.value = clamped;
            root.moved(clamped);
        }

        onPressed: mouse => updateValue(mouse.x)
        onPositionChanged: mouse => {
            if (pressed) updateValue(mouse.x)
        }
    }

    // Track Container
    Item {
        id: trackContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: root.trackHeight

        // Calculated positions
        readonly property real availableWidth: root.width - root.thumbWidth
        readonly property real thumbCenterX: (root.thumbWidth / 2) + availableWidth * root.normalizedValue
        readonly property real activeRight: Math.max(0, thumbCenterX - (root.thumbWidth / 2) - root.gap)
        readonly property real inactiveLeft: Math.min(root.width, thumbCenterX + (root.thumbWidth / 2) + root.gap)

        // Active Track (Left)
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: trackContainer.activeRight
            radius: root.trackHeight / 2
            color: root.activeColor
            visible: width > 0

            Behavior on color {
                ColorAnimation { duration: Motion.durationNormal }
            }
        }

        // Inactive Track (Right)
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(0, parent.width - trackContainer.inactiveLeft)
            radius: root.trackHeight / 2
            color: root.inactiveColor
            visible: width > 0

            Behavior on color {
                ColorAnimation { duration: Motion.durationNormal }
            }
        }
    }

    // Thumb & State Layer
    Item {
        id: thumbItem
        width: root.thumbWidth
        height: root.isPressed ? root.thumbPressedHeight : root.thumbHeight
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(root.width - width, (root.width - width) * root.normalizedValue))

        Behavior on height {
            NumberAnimation {
                duration: Motion.durationShort2
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.standard
            }
        }

        // M3 State Layer (Halo on hover / press)
        Rectangle {
            anchors.centerIn: parent
            width: 34
            height: 34
            radius: 17
            color: root.thumbColor
            opacity: root.isPressed ? 0.16 : (root.isHovered ? 0.08 : 0.0)

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.durationShort2
                }
            }
        }

        // Thumb Pill (M3 Vertical Pill)
        Rectangle {
            anchors.fill: parent
            radius: root.thumbWidth / 2
            color: root.thumbColor

            Behavior on color {
                ColorAnimation { duration: Motion.durationNormal }
            }
        }
    }
}
