import QtQuick
import qs.Common
import qs.Widgets

RippleButton {
    id: button

    property string buttonIcon
    property string buttonText
    property real size: 120

    backgroundColor: (button.focus || button.down) ? Theme.secondary : Theme.surfaceVariant
    buttonHeight: size
    buttonWidth: size

    contentItem: MaterialIcon {
        id: icon

        name: button.buttonIcon
        size: 45
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
            button.clicked();
    }
}
