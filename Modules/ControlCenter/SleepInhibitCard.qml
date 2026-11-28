pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import qs.Common
import qs.Services
import qs.Widgets

Controls.AbstractButton {
    id: root

    readonly property bool active: SleepInhibitService.active

    Accessible.name: text
    Accessible.description: active ? "On" : "Off"
    Accessible.role: Accessible.CheckBox
    Accessible.checked: active
    enabled: SleepInhibitService.available && !SleepInhibitService.busy
    focusPolicy: Qt.StrongFocus
    hoverEnabled: enabled
    implicitHeight: 68
    opacity: SleepInhibitService.available ? Theme.opacityFull : Theme.opacityUnavailable
    text: "Stay Awake"

    background: ControlCenterSurface {
        border.color: Theme.withAlpha(Theme.outline, root.active ? 0.22 : 0.1)
        color: root.active ? Theme.withAlpha(Theme.primary, 0.28) : Theme.withAlpha(Theme.surfaceVariant,
                                                                                    0.38)

        Rectangle {
            anchors.fill: parent
            color: Theme.withAlpha(Theme.surfaceText, root.down ? 0.12 : root.hovered
                                                                  || root.visualFocus ? 0.08 : 0)
            radius: parent.radius
        }
    }

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        Rectangle {
            Layout.preferredHeight: 42
            Layout.preferredWidth: 42
            color: root.active ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.12)
            radius: height / 2

            MaterialIcon {
                anchors.centerIn: parent
                color: root.active ? Theme.primaryText : Theme.surfaceText
                name: "coffee"
                size: Theme.iconSize
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                text: root.text
                wrapMode: Text.NoWrap
            }

            StyledText {
                Layout.fillWidth: true
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: SleepInhibitService.errorText || (SleepInhibitService.busy ? "Applying…" :
                                                                                   !SleepInhibitService.available
                                                                                   ? "Checking…" :
                                                                                     root.active
                                                                                     ? "On" : "Off")
                wrapMode: Text.NoWrap
            }
        }
    }

    onClicked: SleepInhibitService.toggle()
}
