import QtQuick
import QtQuick.Layouts
import qs.theme

ColumnLayout {
    id: root
    spacing: Metrics.layoutSpacing

    property string icon: ""
    property string text: ""
    property bool rotating: false

    Text {
        text: root.icon
        color: Colors.on_surface_variant
        font.family: Typography.iconFamily
        font.pixelSize: Typography.sizeIconLarge
        Layout.alignment: Qt.AlignHCenter

        RotationAnimator on rotation {
            running: root.rotating
            from: 0
            to: 360
            loops: Animation.Infinite
            duration: 1200
        }
    }

    Text {
        text: root.text
        color: Colors.on_surface_variant
        font.family: Typography.family
        font.pixelSize: Typography.sizeCaption
        Layout.alignment: Qt.AlignHCenter
    }
}
