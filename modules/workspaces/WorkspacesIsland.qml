import QtQuick
import QtQuick.Layouts
import qs.components

GlassContainer {
    id: root
    height: 32
    width: wsContent.implicitWidth + 20

    RowLayout {
        id: wsContent
        anchors.centerIn: parent
        Workspaces {}
    }
}
