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
}
