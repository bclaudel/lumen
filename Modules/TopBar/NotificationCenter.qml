pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell

import qs.Common
import qs.Services
import qs.Widgets

TopBarPopup {
    id: root

    popupWidth: 380
    configuredMaximumHeight: 620

    onVisibleChanged: {
        if (visible) {
            NotificationService.markAllRead();
            NotificationService.hideToasts();
        }
    }

    Connections {
        target: NotificationService

        function onHistoryChanged() {
            if (root.visible)
                NotificationService.markAllRead();
        }
    }

    content: Component {
        ColumnLayout {
            width: parent.width
            spacing: Theme.spacingS

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 44

                StyledText {
                    Layout.fillWidth: true
                    font.family: SettingsData.displayFontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    text: "Notifications"
                }

                Controls.AbstractButton {
                    enabled: NotificationService.history.length > 0
                    hoverEnabled: true
                    contentItem: StyledText {
                        color: Theme.primary
                        font.pixelSize: Theme.fontSizeSmall
                        text: "Clear all"
                    }
                    onClicked: NotificationService.clearAll()
                }
            }

            HorizontalSeparator {}

            StyledText {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                color: Theme.surfaceTextMedium
                horizontalAlignment: Text.AlignHCenter
                text: "No notifications"
                visible: NotificationService.history.length === 0
            }

            Repeater {
                model: ScriptModel {
                    values: NotificationService.history.filter(entry => !entry.transient)
                }

                delegate: NotificationCard {
                    required property var modelData
                    Layout.fillWidth: true
                    entry: modelData
                    onDismissRequested: id => NotificationService.dismiss(id)
                    onActionRequested: (id, index) => NotificationService.invokeAction(id, index)
                }
            }
        }
    }
}
