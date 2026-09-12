import QtQuick
import QtQuick.Layouts
import qs.components
import qs.theme
import qs.modules.system

Container {
    id: root
    height: Metrics.islandHeight
    width: wsContent.implicitWidth + 20

    RowLayout {
        id: wsContent
        anchors.centerIn: parent
        spacing: 12

        OsLogo {
            Layout.alignment: Qt.AlignVCenter
        }

        Workspaces {
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
