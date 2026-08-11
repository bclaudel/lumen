import QtQuick

import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property alias text: textInput.text
    property alias echoMode: textInput.echoMode
    property string iconName: ""
    property int iconSize: Theme.iconSize
    property color iconColor: Theme.surfaceVariantText
    property color iconFocusedColor: Theme.primary

    property color backgroundColor: Theme.inputBackground
    property color focusedBorderColor: Theme.primary
    property color normalBorderColor: Theme.outlineStrong
    property color placeholderColor: Theme.outlineButton
    property string placeholderText: ""
    property int borderWidth: 1
    property int focusedBorderWidth: 2
    property real cornerRadius: Theme.cornerRadius

    property real topPadding: Theme.spacingM
    property real bottomPadding: Theme.spacingM
    readonly property real leftPadding: Theme.spacingM + (iconName ? iconSize + Theme.spacingM : 0)
    readonly property real rightPadding: Theme.spacingM

    signal textEdited
    signal accepted

    function forceActiveFocus() {
        textInput.forceActiveFocus();
    }

    width: 200
    height: 48
    radius: Theme.cornerRadius
    color: backgroundColor
    border.color: textInput.activeFocus ? focusedBorderColor : normalBorderColor
    border.width: textInput.activeFocus ? focusedBorderWidth : borderWidth

    MaterialIcon {
        id: icon

        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingM
        anchors.verticalCenter: parent.verticalCenter
        name: root.iconName
        size: root.iconSize
        color: textInput.activeFocus ? root.iconFocusedColor : root.iconColor
        visible: root.iconName !== ""
    }

    StyledText {
        anchors.fill: textInput
        color: root.placeholderColor
        font.pixelSize: textInput.font.pixelSize
        text: root.placeholderText
        visible: textInput.text === "" && !textInput.preeditText
    }

    TextInput {
        id: textInput

        anchors.fill: parent
        anchors.leftMargin: root.leftPadding
        anchors.rightMargin: root.rightPadding
        anchors.topMargin: root.topPadding
        anchors.bottomMargin: root.bottomPadding
        verticalAlignment: TextInput.AlignVCenter
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceText
        onAccepted: root.accepted()
        onTextEdited: root.textEdited()
    }
}
