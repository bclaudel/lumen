pragma ComponentBehavior: Bound

import QtQuick

import qs.Common

Canvas {
    id: root

    property color graphColor: Theme.primary
    property int sampleCapacity: 30
    property var values: []

    implicitHeight: 44

    onGraphColorChanged: requestPaint()
    onValuesChanged: requestPaint()

    onPaint: {
        const context = getContext("2d");
        context.clearRect(0, 0, width, height);

        context.strokeStyle = Theme.withAlpha(Theme.surfaceText, 0.07);
        context.lineWidth = 1;
        for (let index = 1; index < 4; ++index) {
            const y = Math.round(height * index / 4) + 0.5;
            context.beginPath();
            context.moveTo(0, y);
            context.lineTo(width, y);
            context.stroke();
        }

        if (values.length < 2)
        return;

        const step = width / Math.max(1, sampleCapacity - 1);
        const startX = width - step * (values.length - 1);
        const pointY = value => height - Math.max(0, Math.min(100, value)) * height / 100;

        context.beginPath();
        context.moveTo(startX, height);
        for (let index = 0; index < values.length; ++index)
        context.lineTo(startX + index * step, pointY(values[index]));
        context.lineTo(width, height);
        context.closePath();
        const fillGradient = context.createLinearGradient(0, 0, 0, height);
        fillGradient.addColorStop(0, Theme.withAlpha(graphColor, 0.26));
        fillGradient.addColorStop(1, Theme.withAlpha(graphColor, 0.02));
        context.fillStyle = fillGradient;
        context.fill();

        context.beginPath();
        for (let index = 0; index < values.length; ++index) {
            const x = startX + index * step;
            const y = pointY(values[index]);
            if (index === 0)
            context.moveTo(x, y);
            else
            context.lineTo(x, y);
        }
        context.lineWidth = 2;
        context.lineJoin = "round";
        context.strokeStyle = graphColor;
        context.stroke();
    }
}
