import QtQuick

Item {
    id: root

    property alias color: icon.color
    property alias name: icon.name
    property alias size: icon.size

    implicitWidth: Math.ceil(metrics.tightBoundingRect.width)
    implicitHeight: icon.size

    TextMetrics {
        id: metrics

        font: icon.font
        text: icon.name
    }

    MaterialIcon {
        id: icon

        anchors.verticalCenter: parent.verticalCenter
        x: -metrics.tightBoundingRect.x
        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideNone
        wrapMode: Text.NoWrap
    }
}
