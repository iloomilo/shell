import QtQuick
import QtQuick.Layouts
import Quickshell.WindowManager
import qs.theme

Row {
    id: root

    Repeater {
        model: 10

        Item {
            id: slot
            readonly property int wsIndex: index + 1
            readonly property var ws: {
                return WindowManager.windowsets.find(ws => ws.name === String(wsIndex));
            }
            readonly property bool isShown: Boolean(ws && ws.shouldDisplay)
            readonly property bool isActive: Boolean(ws && ws.active)
            width: isShown ? ((isActive ? 40 : 20) + 8) : 0
            height: 10
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                }
            }

            Rectangle {
                color: slot.isActive 
                    ? Colors.primary 
                    : (hover.hovered ? Colors.surface_bright : Colors.surface_container_high)
                width: slot.isActive ? 40 : 20
                height: 10
                radius: 4

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutBack
                    }
                }

                TapHandler {
                    enabled: Boolean(slot.ws)
                    onTapped: slot.ws.activate()
                }

                HoverHandler {
                    id: hover
                    enabled: Boolean(slot.ws)
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
