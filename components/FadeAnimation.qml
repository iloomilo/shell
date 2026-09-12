import QtQuick
import qs.theme

SequentialAnimation {
    property bool entering: true
    property int stagger: 0
    property int enterDuration: Motion.contentEnter

    PauseAnimation {
        duration: entering ? stagger : 0
    }

    NumberAnimation {
        duration: entering ? enterDuration : Motion.contentExit
        easing.type: Easing.Bezier
        easing.bezierCurve: entering ? Motion.emphasizedDecelerate : Motion.emphasizedAccelerate
    }
}
