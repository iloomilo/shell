import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.components
import qs.modules.workspaces
import qs.modules.clock
import qs.modules.status

ShellRoot {
    DismissOverlay {
        active: statusIsland.isExpanded
        onDismissed: statusIsland.currentMenu = ""
    }

    PanelWindow {
        id: root

        WlrLayershell.layer: WlrLayer.Overlay
        implicitHeight: 400
        color: "transparent"
        exclusiveZone: Metrics.exclusiveZone

        anchors {
            top: true
            left: true
            right: true
        }

        mask: Region {
            Region {
                item: workspacesIsland
            }
            Region {
                item: clockIsland
            }
            Region {
                item: statusIsland
            }
        }

        Item {
            id: islandContainer
            anchors.fill: parent
            anchors.topMargin: Metrics.barTopMargin
            anchors.leftMargin: Metrics.barSideMargin
            anchors.rightMargin: Metrics.barSideMargin

            WorkspacesIsland {
                id: workspacesIsland
                anchors.left: parent.left
                anchors.top: parent.top
            }

            ClockIsland {
                id: clockIsland
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
            }

            StatusIsland {
                id: statusIsland
                anchors.right: parent.right
                anchors.top: parent.top
            }
        }
    }
}
