import QtQuick
import QtQuick.Shapes
import qs.theme

// Vector OSD icon that morphs continuously with its value instead of swapping glyphs.
// Drawn on a 24x24 grid and scaled to `size`.
Item {
    id: root

    property string kind: "volume" // "volume" | "brightness"
    property real value: 0.0
    property bool muted: false
    property color color: Colors.primary
    property real size: 18

    implicitWidth: size
    implicitHeight: size

    property real shownValue: Math.max(0.0, Math.min(1.0, value))
    property real mutedProgress: muted ? 1.0 : 0.0
    property real brightnessProgress: kind === "brightness" ? 1.0 : 0.0

    Behavior on shownValue {
        NumberAnimation {
            duration: Motion.durationMedium1
            easing.type: Easing.Bezier
            easing.bezierCurve: Motion.emphasizedDecelerate
        }
    }

    Behavior on mutedProgress {
        NumberAnimation {
            duration: Motion.durationMedium2
            easing.type: Easing.Bezier
            easing.bezierCurve: Motion.emphasized
        }
    }

    Behavior on brightnessProgress {
        NumberAnimation {
            duration: Motion.durationMedium2
            easing.type: Easing.Bezier
            easing.bezierCurve: Motion.emphasized
        }
    }

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, c.a * Math.max(0.0, Math.min(1.0, a)));
    }

    function clamp01(v) {
        return Math.max(0.0, Math.min(1.0, v));
    }

    Item {
        width: 24
        height: 24
        anchors.centerIn: parent
        scale: root.size / 24

        // ── Brightness ───────────────────────────────────────

        Shape {
            id: sun
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: root.brightnessProgress
            scale: 0.6 + 0.4 * root.brightnessProgress
            rotation: -45 * (1 - root.shownValue)
            visible: opacity > 0.001

            readonly property real coreRadius: 3.2 + 1.3 * root.shownValue
            readonly property real rayStart: 6.4
            readonly property real rayLength: 0.2 + 3.4 * root.shownValue

            ShapePath {
                strokeColor: "transparent"
                fillColor: root.color

                PathAngleArc {
                    centerX: 12
                    centerY: 12
                    radiusX: sun.coreRadius
                    radiusY: sun.coreRadius
                    startAngle: 0
                    sweepAngle: 360
                }
            }

            ShapePath {
                strokeColor: root.color
                strokeWidth: 2
                capStyle: ShapePath.RoundCap
                fillColor: "transparent"

                PathSvg {
                    path: {
                        let d = "";
                        for (let i = 0; i < 8; i++) {
                            const a = i * Math.PI / 4;
                            const cx = Math.cos(a), cy = Math.sin(a);
                            const r0 = sun.rayStart, r1 = sun.rayStart + sun.rayLength;
                            d += "M " + (12 + cx * r0) + " " + (12 + cy * r0) + " L " + (12 + cx * r1) + " " + (12 + cy * r1) + " ";
                        }
                        return d;
                    }
                }
            }
        }

        // ── Volume ───────────────────────────────────────────

        Shape {
            id: speaker
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: 1 - root.brightnessProgress
            scale: 1 - 0.4 * root.brightnessProgress
            visible: opacity > 0.001

            // Waves grow in one after another as the volume rises and collapse when muted
            readonly property real wave1: root.clamp01(root.shownValue * 3) * (1 - root.mutedProgress)
            readonly property real wave2: root.clamp01((root.shownValue - 0.4) * 2.5) * (1 - root.mutedProgress)

            ShapePath {
                strokeColor: "transparent"
                fillColor: root.color

                PathSvg {
                    path: "M 3 9.5 Q 3 9 3.5 9 L 7 9 L 11.3 4.7 Q 12 4 12 5 L 12 19 Q 12 20 11.3 19.3 L 7 15 L 3.5 15 Q 3 15 3 14.5 Z"
                }
            }

            ShapePath {
                strokeColor: root.withAlpha(root.color, speaker.wave1 * 4)
                strokeWidth: 2
                capStyle: ShapePath.RoundCap
                fillColor: "transparent"

                PathAngleArc {
                    centerX: 12
                    centerY: 12
                    radiusX: 3.5
                    radiusY: 3.5
                    startAngle: -50 * speaker.wave1
                    sweepAngle: 100 * speaker.wave1
                }
            }

            ShapePath {
                strokeColor: root.withAlpha(root.color, speaker.wave2 * 4)
                strokeWidth: 2
                capStyle: ShapePath.RoundCap
                fillColor: "transparent"

                PathAngleArc {
                    centerX: 12
                    centerY: 12
                    radiusX: 7.5
                    radiusY: 7.5
                    startAngle: -55 * speaker.wave2
                    sweepAngle: 110 * speaker.wave2
                }
            }

            // Mute slash draws in from the top-left corner
            ShapePath {
                strokeColor: root.withAlpha(root.color, root.mutedProgress * 4)
                strokeWidth: 2
                capStyle: ShapePath.RoundCap
                fillColor: "transparent"
                startX: 4
                startY: 4

                PathLine {
                    x: 4 + 16 * root.mutedProgress
                    y: 4 + 16 * root.mutedProgress
                }
            }
        }
    }
}
