import QtQuick

// Scrolling line graph (like a heart-rate monitor) of `value` (0..1),
// sampled every `interval` ms.
Item {
    id: w

    property real value: 0
    property int interval: 120
    property int samples: 90
    property color accent: "#ff7b1c"
    property color grid: "#1c2730"
    property bool running: true

    property var points: []

    Timer {
        interval: w.interval
        running: w.running
        repeat: true
        onTriggered: {
            // a little jitter so a flat load still breathes
            const v = Math.max(0, Math.min(1, w.value + (Math.random() - 0.5) * 0.04));
            const d = w.points.slice(-(w.samples - 1));
            d.push(v);
            w.points = d;
            canvas.requestPaint();
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        layer.enabled: true
        layer.effect: Glow { color: w.accent; strength: 0.8 }
        onPaint: {
            const g = getContext("2d");
            g.clearRect(0, 0, width, height);
            g.strokeStyle = w.grid;
            g.lineWidth = 1;
            for (let i = 1; i < 4; i++) {
                const y = Math.round(height * i / 4) + 0.5;
                g.beginPath(); g.moveTo(0, y); g.lineTo(width, y); g.stroke();
            }
            const d = w.points;
            if (d.length < 2) return;
            const step = width / (w.samples - 1);
            const x0 = width - (d.length - 1) * step;
            g.strokeStyle = w.accent;
            g.lineWidth = 2;
            g.beginPath();
            for (let i = 0; i < d.length; i++) {
                const x = x0 + i * step, y = height - 4 - d[i] * (height - 8);
                if (i === 0) g.moveTo(x, y); else g.lineTo(x, y);
            }
            g.stroke();
            // head
            const hy = height - 4 - d[d.length - 1] * (height - 8);
            g.fillStyle = "#ffffff";
            g.fillRect(width - 3, hy - 2, 4, 4);
        }
    }
}
