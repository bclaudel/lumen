import QtQuick
import qs.Common
import qs.Widgets

IconButton {
    id: button

    property string buttonIcon
    property string buttonText
    property real size: 120

    accessibleName: buttonText
    backgroundColor: (button.focus || button.down || button.hovered) ? Theme.buttonActiveBackground :
                                                                       Theme.buttonBackground
    buttonHeight: size
    buttonRadius: Theme.cornerRadius
    buttonWidth: size
    circular: false
    iconName: buttonIcon
    iconSize: 45
    stateLayerEnabled: false

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
            button.clicked();
    }
}
