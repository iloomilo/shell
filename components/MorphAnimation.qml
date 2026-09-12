import QtQuick
import qs.theme

NumberAnimation {
    property bool expanding: true

    duration: expanding ? Motion.morphEnter : Motion.morphExit
    easing.type: Easing.Bezier
    easing.bezierCurve: Motion.emphasized
}
