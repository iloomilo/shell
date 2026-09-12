import QtQuick
import qs.theme
import qs.services

Item {
    id: root

    property bool active: false
    property color color: Colors.primary
    property color colorAlt: Colors.tertiary
    property real cornerRadius: Metrics.radiusContainer

    readonly property int points: Cava.bars

    property real falloff: active ? 1.0 : 0.0

    Behavior on falloff {
        NumberAnimation {
            duration: root.active ? 350 : 500
            easing.type: root.active ? Easing.OutCubic : Easing.InQuad
        }
    }

    readonly property bool wantsData: active && visible && Cava.available
    property bool holding: false

    onWantsDataChanged: {
        if (wantsData) {
            lingerTimer.stop();
            if (!holding) {
                Cava.acquire();
                holding = true;
            }
        } else if (holding) {
            lingerTimer.restart();
        }
    }

    Timer {
        id: lingerTimer
        interval: 4000
        onTriggered: {
            if (root.holding && !root.wantsData) {
                Cava.release();
                root.holding = false;
            }
        }
    }

    Component.onCompleted: if (wantsData) {
        Cava.acquire();
        holding = true;
    }

    Component.onDestruction: if (holding)
        Cava.release()

    property var levels: []

    readonly property bool animating: (active || falloff > 0.001) && visible && Cava.available

    function resetLevels() {
        const out = [];
        for (let i = 0; i < points; i++)
            out.push(0);
        levels = out;
    }

    onPointsChanged: resetLevels()

    function step() {
        if (levels.length !== points)
            resetLevels();

        const src = Cava.values;
        const next = [];
        for (let i = 0; i < points; i++) {
            const target = ((src && i < src.length) ? src[i] : 0) * falloff;
            const prev = levels[i] || 0;
            const rate = target > prev ? 0.45 : 0.12;
            next.push(prev + (target - prev) * rate);
        }
        levels = next;
        canvas.requestPaint();
    }

    Timer {
        interval: 16
        running: root.animating
        repeat: true
        onTriggered: root.step()
    }

    onAnimatingChanged: if (!animating) {
        resetLevels();
        canvas.requestPaint();
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        function blur(src, radius) {
            if (radius <= 0)
                return src;

            const out = [];
            for (let i = 0; i < src.length; i++) {
                let sum = 0;
                let n = 0;
                for (let k = -radius; k <= radius; k++) {
                    const j = i + k;
                    if (j < 0 || j >= src.length)
                        continue;
                    const w = radius + 1 - Math.abs(k);
                    sum += src[j] * w;
                    n += w;
                }
                out.push(n > 0 ? sum / n : 0);
            }
            return out;
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            const w = width;
            const h = height;
            if (w <= 0 || h <= 0)
                return;

            const f = root.falloff;
            if (f <= 0.0001 || !Cava.available)
                return;

            const lv = root.levels;
            const n = lv.length;
            if (n < 2)
                return;

            const cr = root.color.r;
            const cg = root.color.g;
            const cb = root.color.b;

            const ar = root.colorAlt.r;
            const ag = root.colorAlt.g;
            const ab = root.colorAlt.b;

            function spectrum(alpha) {
                const g = ctx.createLinearGradient(0, 0, w, 0);
                g.addColorStop(0.0, Qt.rgba(cr, cg, cb, alpha));
                g.addColorStop(0.45, Qt.rgba(cr, cg, cb, alpha));
                g.addColorStop(1.0, Qt.rgba(ar, ag, ab, alpha));
                return g;
            }

            const r = Math.max(0, Math.min(root.cornerRadius, w / 2, h));
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(w, 0);
            ctx.lineTo(w, h - r);
            ctx.quadraticCurveTo(w, h, w - r, h);
            ctx.lineTo(r, h);
            ctx.quadraticCurveTo(0, h, 0, h - r);
            ctx.closePath();
            ctx.clip();

            function envelope(norm) {
                return Math.pow(Math.sin(norm * Math.PI), 0.65);
            }

            function drawLayer(src, scale, base, fillCol, strokeCol) {
                const pts = [];
                for (let i = 0; i < n; i++) {
                    const norm = i / (n - 1);
                    const amp = (base + src[i] * scale) * envelope(norm) * f;
                    pts.push({
                        x: norm * w,
                        y: h - Math.min(h, amp)
                    });
                }

                function trace() {
                    ctx.moveTo(pts[0].x, pts[0].y);
                    for (let i = 0; i < n - 1; i++) {
                        const mx = (pts[i].x + pts[i + 1].x) / 2;
                        const my = (pts[i].y + pts[i + 1].y) / 2;
                        ctx.quadraticCurveTo(pts[i].x, pts[i].y, mx, my);
                    }
                    ctx.lineTo(pts[n - 1].x, pts[n - 1].y);
                }

                ctx.beginPath();
                ctx.moveTo(0, h);
                ctx.lineTo(pts[0].x, pts[0].y);
                trace();
                ctx.lineTo(w, h);
                ctx.closePath();
                ctx.fillStyle = fillCol;
                ctx.fill();

                if (strokeCol) {
                    ctx.beginPath();
                    trace();
                    ctx.strokeStyle = strokeCol;
                    ctx.lineWidth = 1.0;
                    ctx.stroke();
                }
            }

            const back = canvas.blur(lv, 3);
            const mid = canvas.blur(lv, 1);

            drawLayer(back, h * 0.92, h * 0.10, spectrum(0.08 * f), null);
            drawLayer(mid, h * 0.70, h * 0.08, spectrum(0.16 * f), null);
            drawLayer(lv, h * 0.50, h * 0.05, spectrum(0.24 * f), spectrum(0.40 * f));
        }
    }
}
