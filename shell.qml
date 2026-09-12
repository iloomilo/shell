import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.components
import qs.modules.workspaces
import qs.modules.dynamicisland
import qs.modules.status

ShellRoot {
    DismissOverlay {
        active: statusIsland.isExpanded
        onDismissed: statusIsland.currentMenu = ""
    }

    PanelWindow {
        id: root

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: statusIsland.requiresKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
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
                item: dynamicIsland
            }
            Region {
                item: statusHitArea
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

            DynamicIsland {
                id: dynamicIsland
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
            }

            Item {
                id: statusHitArea
                anchors.right: parent.right
                anchors.top: parent.top
                width: (statusIsland.isExpanded || collapseTimer.running) ? Metrics.expandedWidth : statusIsland.collapsedWidth
                height: (statusIsland.isExpanded || collapseTimer.running) ? Metrics.expandedHeight : Metrics.islandHeight
            }

            Timer {
                id: collapseTimer
                interval: Motion.morphExit + 30
                repeat: false
            }

            Connections {
                target: statusIsland
                function onIsExpandedChanged() {
                    if (!statusIsland.isExpanded) {
                        collapseTimer.restart();
                    }
                }
            }

            StatusIsland {
                id: statusIsland
                anchors.right: parent.right
                anchors.top: parent.top
            }
        }
    }
}
