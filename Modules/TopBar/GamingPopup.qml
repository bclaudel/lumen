pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import qs.Common
import qs.Services
import qs.Widgets

TopBarPopup {
    id: root

    onVisibleChanged: {
        LactService.monitoring = visible;
        if (visible) {
            GamepadService.refresh();
            LactService.refresh();
        }
    }

    content: Component {
        ColumnLayout {
            spacing: Theme.spacingXS
            width: parent.width

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingS
                Layout.preferredHeight: 44
                Layout.rightMargin: Theme.spacingS

                StyledText {
                    Layout.fillWidth: true
                    color: Theme.surfaceText
                    font.family: SettingsData.displayFontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    text: "Gaming"
                }
            }

            HorizontalSeparator {}

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingM
                Layout.preferredHeight: 30
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                text: "GAMING DEVICES"
                verticalAlignment: Text.AlignVCenter
            }

            Repeater {
                model: GamepadService.devices

                delegate: GamingDeviceRow {
                    required property var modelData

                    Layout.fillWidth: true
                    device: modelData
                }
            }

            HorizontalSeparator {}

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingM
                Layout.preferredHeight: 30
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                text: "GPU PROFILE"
                verticalAlignment: Text.AlignVCenter
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingM
                Layout.preferredHeight: 38
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: LactService.loading ? "Loading GPU profiles…" : "No GPU profiles available"
                verticalAlignment: Text.AlignVCenter
                visible: LactService.profiles.length === 0 && LactService.errorText === ""
            }

            Repeater {
                model: LactService.profiles

                delegate: GamingProfileRow {
                    required property string modelData

                    Layout.fillWidth: true
                    active: modelData === LactService.currentProfile
                    busy: modelData === LactService.applyingProfile
                    interactionBlocked: LactService.applyingProfile !== ""
                    profileName: modelData

                    onActivated: profileName => LactService.setProfile(profileName)
                }
            }

            StyledText {
                Layout.bottomMargin: Theme.spacingS
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingM
                Layout.rightMargin: Theme.spacingM
                Layout.topMargin: Theme.spacingS
                color: Theme.error
                font.pixelSize: Theme.fontSizeSmall
                text: LactService.errorText
                visible: text !== ""
                wrapMode: Text.Wrap
            }

            HorizontalSeparator {}

            Controls.AbstractButton {
                id: settingsButton

                Accessible.name: "GPU Settings"
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                hoverEnabled: true

                background: Rectangle {
                    color: "transparent"
                    radius: Theme.cornerRadius

                    StateOverlay {
                        hovered: settingsButton.hovered
                        pressed: settingsButton.down
                        focused: settingsButton.visualFocus
                    }
                }

                contentItem: RowLayout {
                    MaterialIcon {
                        Layout.leftMargin: Theme.spacingM
                        name: "settings"
                        size: Theme.iconSize
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        text: "GPU Settings…"
                    }

                    MaterialIcon {
                        Layout.rightMargin: Theme.spacingM
                        color: Theme.surfaceTextMedium
                        name: "chevron_right"
                        size: Theme.iconSizeSmall
                    }
                }

                onClicked: {
                    root.close();
                    LactService.openSettings();
                }
            }
        }
    }
}
