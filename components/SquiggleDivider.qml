import QtQuick
import qs.theme

Canvas {
    id: root

    property bool active: false
    property real phase: 0.0
    property real targetAmplitude: active ? 3.0 : 0.0
    property real amplitude: targetAmplitude
    property color strokeColor: active ? Colors.primary : Colors.surface_container_highest

    implicitHeight: 16

    Behavior on amplitude {
        NumberAnimation { duration: 350; easing.type: Motion.easingStandard }
    }

    Behavior on strokeColor {
        ColorAnimation { duration: Motion.durationMorph }
    }

    onPhaseChanged: requestPaint()
    onAmplitudeChanged: requestPaint()
    onStrokeColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        let ctx = getContext("2d");
        ctx.reset();
        ctx.lineWidth = 1.5;
        ctx.strokeStyle = strokeColor;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        ctx.beginPath();
        let cy = height / 2;
        let wl = 20;

        ctx.moveTo(0, cy + Math.sin(phase) * amplitude);
        for (let x = 1; x <= width; x += 2) {
            let y = cy + Math.sin((x / wl) * Math.PI * 2 + phase) * amplitude;
            ctx.lineTo(x, y);
        }
        ctx.stroke();
    }

    NumberAnimation on phase {
        running: root.visible && (root.active || root.amplitude > 0.05)
        from: 0
        to: -Math.PI * 2
        duration: Motion.durationWave
        loops: Animation.Infinite
    }
}
