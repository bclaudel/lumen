pragma ComponentBehavior: Bound

import QtQuick

import qs.Common

Item {
    id: root

    property bool available: true
    property color accent: Theme.primary
    property real value: 0
    property string caption: "Usage"
    readonly property real boundedValue: available ? Math.max(0, Math.min(100, value)) : 0
    property real displayedValue: boundedValue

    implicitHeight: 112
    implicitWidth: 112

    Behavior on displayedValue {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Canvas {
        id: ring

        readonly property color accent: root.accent
        readonly property color track: Theme.withAlpha(root.accent, 0.16)
        readonly property real value: root.displayedValue

        anchors.fill: parent
        onAccentChanged: requestPaint()
        onTrackChanged: requestPaint()
        onValueChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const radius = Math.min(width, height) / 2 - 6;
            if (radius <= 0)
                return;
            const start = 3 * Math.PI / 4;
            const sweep = 3 * Math.PI / 2;
            ctx.lineWidth = 7;
            ctx.lineCap = "round";
            ctx.strokeStyle = track;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, radius, start, start + sweep);
            ctx.stroke();
            if (value > 0) {
                ctx.strokeStyle = accent;
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, radius, start, start + sweep * value / 100);
                ctx.stroke();
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.available ? root.accent : Theme.surfaceTextMedium
            font.pixelSize: Theme.fontSizeXXLarge
            font.weight: Font.DemiBold
            text: root.available ? Math.round(root.boundedValue) + "%" : "—"
            wrapMode: Text.NoWrap
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.surfaceTextMedium
            font.pixelSize: Theme.fontSizeSmall
            text: root.available ? root.caption : "Unavailable"
            wrapMode: Text.NoWrap
        }
    }
}
