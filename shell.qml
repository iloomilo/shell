import Quickshell
import QtQuick
import qs.modules.workspaces
import qs.modules.clock
import qs.modules.status

ShellRoot {
    PanelWindow {
        id: root

        implicitHeight: 400
        color: "transparent"
        exclusiveZone: 44

        anchors {
            top: true
            left: true
            right: true
        }

        mask: Region {
            Region {
                item: barHitArea
            }
            Region {
                item: clockIsland
            }
            Region {
                item: statusIsland
            }
        }

        Item {
            id: barHitArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 44
        }

        Item {
            id: islandContainer
            anchors.fill: parent
            anchors.topMargin: 8
            anchors.bottomMargin: 6
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            WorkspacesIsland {
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
