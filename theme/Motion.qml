pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property real springStiffness: 3.5
    readonly property real springDamping: 0.45
    readonly property real springEpsilon: 0.25
    readonly property real springScaleEpsilon: 0.01

    readonly property int durationFast: 120
    readonly property int durationNormal: 150
    readonly property int durationSlow: 200
    readonly property int durationMorph: 300
    readonly property int durationWave: 800
    readonly property int durationSpin: 1000

    readonly property int easingStandard: Easing.OutCubic
    readonly property int easingTactile: Easing.OutQuad
    readonly property int easingExpressive: Easing.OutBack

    readonly property var emphasized: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var emphasizedDecelerate: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property var emphasizedAccelerate: [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
    readonly property var standard: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var standardDecelerate: [0.0, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var standardAccelerate: [0.3, 0.0, 1.0, 1.0, 1.0, 1.0]

    readonly property int durationShort2: 100
    readonly property int durationShort3: 150
    readonly property int durationShort4: 200
    readonly property int durationMedium1: 250
    readonly property int durationMedium2: 300
    readonly property int durationMedium4: 400
    readonly property int durationLong2: 500

    readonly property int morphEnter: 280
    readonly property int morphExit: 220
    readonly property int contentEnter: durationShort4
    readonly property int contentExit: durationShort2
    readonly property int contentStagger: 180
    readonly property int collapseStagger: 150
    readonly property int collapseEnter: durationShort2
    readonly property int contentFade: durationShort2
}
