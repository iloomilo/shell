import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import qs.theme
import qs.components
import qs.services as Services
import qs.modules.workspaces
import qs.modules.dynamicisland
import qs.modules.status
import qs.modules.lock

ShellRoot {
    id: shell

    // The main monitor hosts the dynamic and status islands (and the OS logo).
    // Every other monitor only gets a workspaces bar. Change this expression,
    // e.g. `Quickshell.screens.find(s => s.name === "DP-1")`, to pick another.
    readonly property var primaryScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    LockScreen {}

    IpcHandler {
        target: "launcher"
        function toggle() {
            Services.DynamicIsland.toggleLauncher();
        }
        function open() {
            Services.DynamicIsland.openLauncher();
        }
        function close() {
            Services.DynamicIsland.closeLauncher();
        }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle() {
            Services.DynamicIsland.toggleWallpaper();
        }
        function refresh() {
            Services.WallpaperService.refresh();
        }
        function open() {
            Services.DynamicIsland.openWallpaper();
        }
        function close() {
            Services.DynamicIsland.closeWallpaper();
        }
    }

    // Main bar: workspaces, dynamic island and status island.
    PanelWindow {
        id: mainBar

        visible: shell.primaryScreen !== null
        screen: shell.primaryScreen

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: Services.DynamicIsland.isPicker
            ? WlrKeyboardFocus.Exclusive
            : (statusIsland.requiresKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)
        implicitHeight: 560
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
                item: dynamicHitArea
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
                screen: shell.primaryScreen
                anchors.left: parent.left
                anchors.top: parent.top
            }

            DynamicIsland {
                id: dynamicIsland
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
            }

            Item {
                id: dynamicHitArea
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: (Services.DynamicIsland.isPicker || dynamicCollapseTimer.running) ? Math.max(480, dynamicIsland.width) : dynamicIsland.width
                height: (Services.DynamicIsland.isPicker || dynamicCollapseTimer.running) ? Math.max(420, dynamicIsland.height) : dynamicIsland.height
            }

            Timer {
                id: dynamicCollapseTimer
                interval: Motion.morphExit + 30
                repeat: false
            }

            Connections {
                target: Services.DynamicIsland
                function onIsPickerChanged() {
                    if (!Services.DynamicIsland.isPicker) {
                        dynamicCollapseTimer.restart();
                    }
                }
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

    // Workspaces-only bars on the remaining monitors.
    Variants {
        model: Quickshell.screens.filter(s => s !== shell.primaryScreen)

        PanelWindow {
            id: sideBar

            required property var modelData

            screen: modelData

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            implicitHeight: Metrics.exclusiveZone
            color: "transparent"
            exclusiveZone: Metrics.exclusiveZone

            anchors {
                top: true
                left: true
                right: true
            }

            mask: Region {
                Region {
                    item: sideWorkspaces
                }
            }

            WorkspacesIsland {
                id: sideWorkspaces
                screen: sideBar.modelData
                showLogo: false
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: Metrics.barSideMargin
                anchors.topMargin: Metrics.barTopMargin
            }
        }
    }
}
