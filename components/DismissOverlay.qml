import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    property bool active: false
    signal dismissed()

    visible: active
    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Item {
        anchors.fill: parent

        TapHandler {
            onTapped: root.dismissed()
        }
    }
}
