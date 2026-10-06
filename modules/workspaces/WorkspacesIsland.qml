import QtQuick
import QtQuick.Layouts
import qs.components
import qs.theme
import qs.modules.system

Container {
    id: root

    // Monitor this bar belongs to; forwarded to Workspaces so it only shows
    // that monitor's workspaces.
    property var screen: null
    // The OS logo is only shown on the primary bar.
    property bool showLogo: true

    height: Metrics.islandHeight
    width: wsContent.implicitWidth + 20

    RowLayout {
        id: wsContent
        anchors.centerIn: parent
        spacing: 12

        OsLogo {
            Layout.alignment: Qt.AlignVCenter
            visible: root.showLogo
        }

        Workspaces {
            Layout.alignment: Qt.AlignVCenter
            screen: root.screen
        }
    }
}
