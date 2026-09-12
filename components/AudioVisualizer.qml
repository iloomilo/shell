import QtQuick
import qs.theme
import qs.services

Row {
    id: root
    spacing: 2
    height: 14

    property bool active: false
    property color color: Colors.primary

    readonly property var slots: [0.12, 0.34, 0.58, 0.80]

    property bool holding: false
    readonly property bool wantsData: active && visible && Cava.available

    onWantsDataChanged: {
        if (wantsData && !holding) {
            Cava.acquire();
            holding = true;
        } else if (!wantsData && holding) {
            Cava.release();
            holding = false;
        }
    }

    Component.onCompleted: if (wantsData) {
        Cava.acquire();
        holding = true;
    }

    Component.onDestruction: if (holding)
        Cava.release()

    Repeater {
        model: [
            { minH: 4, maxH: 12 },
            { minH: 5, maxH: 14 },
            { minH: 3, maxH: 11 },
            { minH: 4, maxH: 13 }
        ]

        Rectangle {
            readonly property real level: {
                if (!root.active)
                    return 0;
                const src = Cava.values;
                if (!src || src.length === 0)
                    return 0;
                const i = Math.min(src.length - 1, Math.round(root.slots[index] * (src.length - 1)));
                return src[i];
            }

            width: 2.5
            height: root.active ? modelData.minH + level * (modelData.maxH - modelData.minH) : 3
            radius: 1
            color: root.color
            anchors.bottom: parent.bottom

            Behavior on height {
                NumberAnimation {
                    duration: 90
                    easing.type: Easing.OutQuad
                }
            }
        }
    }
}
