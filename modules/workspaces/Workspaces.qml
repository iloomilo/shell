import QtQuick
import Quickshell.WindowManager
import qs.theme

Row {
    id: root

    readonly property real gap: 6
    readonly property real pillHeight: 12
    readonly property real activeWidth: 26
    readonly property real idleWidth: 12

    height: 20

    Repeater {
        model: 10

        Item {
            id: slot

            readonly property int wsIndex: index + 1
            readonly property var ws: WindowManager.windowsets.find(w => w.name === String(wsIndex))
            readonly property bool isShown: Boolean(ws && ws.shouldDisplay)
            readonly property bool isActive: Boolean(ws && ws.active)
            readonly property bool isUrgent: Boolean(ws && ws.urgent && !ws.active)

            readonly property real leadGap: index > 0 ? root.gap : 0

            width: isShown ? (isActive ? root.activeWidth : root.idleWidth) + leadGap : 0
            height: root.height

            Behavior on width {
                NumberAnimation {
                    duration: Motion.durationMorph
                    easing.type: Motion.easingExpressive
                }
            }

            Rectangle {
                id: pill

                width: Math.max(0, slot.width - slot.leadGap)
                height: root.pillHeight
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                radius: root.pillHeight / 2

                color: {
                    if (slot.isUrgent)
                        return Colors.error;
                    if (slot.isActive)
                        return Colors.primary;
                    return hover.hovered ? Colors.secondary : Colors.secondary_container;
                }

                scale: hover.hovered && !slot.isActive ? 1.15 : 1.0

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationNormal
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingTactile
                    }
                }

                SequentialAnimation on opacity {
                    running: slot.isUrgent
                    loops: Animation.Infinite
                    alwaysRunToEnd: true

                    NumberAnimation {
                        to: 0.45
                        duration: 500
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 1.0
                        duration: 500
                        easing.type: Easing.InOutSine
                    }
                }
            }

            HoverHandler {
                id: hover
                enabled: slot.isShown
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                enabled: Boolean(slot.ws) && slot.ws.canActivate
                onTapped: slot.ws.activate()
            }
        }
    }
}
