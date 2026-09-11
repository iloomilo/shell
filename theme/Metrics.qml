pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property real barHeight: 44
    readonly property real islandHeight: 32
    readonly property real expandedWidth: 280
    readonly property real expandedHeight: 300
    readonly property real expandedHeroX: 16

    readonly property real sidePadding: 12
    readonly property real itemSpacing: 10
    readonly property real layoutSpacing: 6

    readonly property real radiusSmall: 4
    readonly property real radiusCard: 12
    readonly property real radiusPill: 16
    readonly property real radiusContainer: 24

    readonly property real itemHeightNormal: 38
    readonly property real itemHeightActive: 42
    readonly property real avatarSize: 26

    readonly property real glassOpacity: 0.85
    readonly property real islandOpacity: 0.92
}
