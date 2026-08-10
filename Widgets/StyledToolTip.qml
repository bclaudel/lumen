import QtQuick
import QtQuick.Controls as Controls

import qs.Common
import qs.Widgets

Controls.ToolTip {
    id: root

    delay: 500

    background: Rectangle {
        border.color: Theme.outlineMedium
        border.width: 1
        color: Theme.popupBackground()
        radius: Theme.cornerRadius
    }

    contentItem: StyledText {
        color: Theme.surfaceText
        font.pixelSize: Theme.fontSizeSmall
        text: root.text
    }
}
