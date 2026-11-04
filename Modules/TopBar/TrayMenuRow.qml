pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Common
import qs.Widgets

Controls.AbstractButton {
    id: root

    required property var entry
    readonly property string label: (entry?.text ?? "").replace(/&&/g, "\u0000").replace(/&/g,
                                                                                         "").replace(
                                        /\u0000/g, "&")
    readonly property bool toggle: entry?.buttonType === QsMenuButtonType.CheckBox || entry
                                   ?.buttonType === QsMenuButtonType.RadioButton
    readonly property string fallbackIcon: {
        const text = label.toLowerCase();
        if (text === "back")
            return "arrow_back";
        if (entry?.hasChildren)
            return "folder";
        if (/\b(quit|exit)\b/.test(text))
            return "logout";
        if (/\b(disconnect)\b/.test(text))
            return "link_off";
        if (/\b(connect)\b/.test(text))
            return "link";
        if (/\b(settings|preferences|options)\b/.test(text))
            return "settings";
        if (/\b(logs?|about|help)\b/.test(text))
            return "description";
        if (/\b(show|open|restore)\b/.test(text))
            return "open_in_new";
        return "apps";
    }

    Accessible.name: label
    enabled: entry?.enabled !== false
    hoverEnabled: enabled
    implicitHeight: 38
    leftPadding: Theme.spacingM
    rightPadding: Theme.spacingM
    opacity: enabled ? Theme.opacityFull : Theme.opacityDisabled

    background: Rectangle {
        color: "transparent"
        radius: Theme.cornerRadius

        StateOverlay {
            hovered: root.hovered
            pressed: root.down
            focused: root.visualFocus
        }
    }

    contentItem: RowLayout {
        spacing: Theme.spacingM

        Item {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20

            IconImage {
                id: actionIcon

                anchors.fill: parent
                source: root.entry?.icon ?? ""
                visible: !root.toggle && status === Image.Ready
            }

            MaterialIcon {
                anchors.centerIn: parent
                size: 20
                name: root.toggle ? root.entry?.buttonType === QsMenuButtonType.RadioButton
                                    ? root.entry?.checkState === Qt.Checked
                                      ? "radio_button_checked" : "radio_button_unchecked" :
                                        root.entry?.checkState === Qt.Checked ? "check_box" :
                                                                                "check_box_outline_blank" :
                                                                                root.fallbackIcon
                color: root.toggle && root.entry?.checkState === Qt.Checked ? Theme.primary :
                                                                              Theme.surfaceText
                visible: root.toggle || !actionIcon.visible
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.label
            textFormat: Text.PlainText
            wrapMode: Text.NoWrap
            font.pixelSize: Theme.fontSizeMedium
        }

        MaterialIcon {
            name: "chevron_right"
            size: Theme.iconSizeSmall
            color: Theme.surfaceTextMedium
            visible: root.entry?.hasChildren ?? false
        }
    }
}
