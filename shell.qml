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

    // The OS logo is only drawn on the first screen's bar. Match on `.name`
    // instead if you want to pin it to a specific monitor, e.g.
    // `Quickshell.screens.find(s => s.name === "DP-1")`.
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

    // A bar per connected monitor, holding the workspaces and status islands.
    // The dynamic island is only instantiated on the focused bar (via Loader)
    // so there is exactly one of it, without a second layer surface that would
    // get pushed down by the bar's exclusive zone.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData

            readonly property bool isFocused: Services.Niri.focusedScreen === modelData
            readonly property bool isPrimary: shell.primaryScreen === modelData

            screen: modelData

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: {
                if (bar.isFocused && Services.DynamicIsland.isPicker)
                    return WlrKeyboardFocus.Exclusive;
                return statusIsland.requiresKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None;
            }
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
                id: barContent
                anchors.fill: parent
                anchors.topMargin: Metrics.barTopMargin
                anchors.leftMargin: Metrics.barSideMargin
                anchors.rightMargin: Metrics.barSideMargin

                readonly property var island: dynamicIslandLoader.item
                readonly property real islandWidth: island ? island.width : 0
                readonly property real islandHeight: island ? island.height : 0

                WorkspacesIsland {
                    id: workspacesIsland
                    screen: bar.modelData
                    showLogo: bar.isPrimary
                    anchors.left: parent.left
                    anchors.top: parent.top
                }

                Loader {
                    id: dynamicIslandLoader
                    active: bar.isFocused
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: barContent.islandWidth
                    height: barContent.islandHeight
                    sourceComponent: DynamicIsland {}
                }

                Item {
                    id: dynamicHitArea
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: !bar.isFocused ? 0 : ((Services.DynamicIsland.isPicker || dynamicCollapseTimer.running) ? Math.max(480, barContent.islandWidth) : barContent.islandWidth)
                    height: !bar.isFocused ? 0 : ((Services.DynamicIsland.isPicker || dynamicCollapseTimer.running) ? Math.max(420, barContent.islandHeight) : barContent.islandHeight)
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
    }
}
