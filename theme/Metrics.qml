pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property real exclusiveZone: 44
    readonly property real barTopMargin: 12
    readonly property real barSideMargin: 20

    readonly property real barHeight: 44
    readonly property real islandHeight: 32
    readonly property real expandedWidth: 280
    readonly property real expandedHeight: 320
    readonly property real expandedHeroX: 16

    readonly property real sidePadding: 12
    readonly property real itemSpacing: 10
    readonly property real layoutSpacing: 6

    readonly property real radiusSmall: 8
    readonly property real radiusCard: 16
    readonly property real radiusPill: 16
    readonly property real radiusContainer: 24
    readonly property real radiusLarge: 28
    readonly property real radiusDialog: 28

    readonly property real itemHeightNormal: 38
    readonly property real itemHeightActive: 42
    readonly property real avatarSize: 26

    readonly property real glassOpacity: 1.0
    readonly property real islandOpacity: 1.0
}
