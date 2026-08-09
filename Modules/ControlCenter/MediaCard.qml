import QtQuick
import QtQuick.Layouts

import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    border.color: Theme.withAlpha(Theme.outline, 0.1)
    border.width: 1
    color: Theme.withAlpha(Theme.surfaceVariant, 0.38)
    implicitHeight: 174
    opacity: MediaService.available ? 1 : 0.78
    radius: Theme.cornerRadius + 6

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: Theme.spacingM

            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.preferredHeight: 62
                Layout.preferredWidth: 62
                clip: true
                color: Theme.withAlpha(Theme.surfaceText, 0.1)
                radius: Theme.cornerRadius

                Image {
                    id: artwork

                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    source: MediaService.artworkUrl
                    visible: MediaService.artworkUrl !== "" && status === Image.Ready
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    color: Theme.surfaceTextMedium
                    name: "music_note"
                    size: Theme.iconSizeLarge
                    visible: MediaService.artworkUrl === "" || artwork.status !== Image.Ready
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    maximumLineCount: 2
                    text: MediaService.title
                }

                StyledText {
                    Layout.fillWidth: true
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    text: MediaService.available ? MediaService.artist : ""
                    visible: text !== ""
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacingS

            MaterialButton {
                buttonSize: 34
                enabled: MediaService.canGoPrevious
                iconColor: Theme.surfaceText
                iconName: "skip_previous"
                opacity: enabled ? 1 : Theme.opacityDisabled

                onClicked: MediaService.previous()
            }

            MaterialButton {
                backgroundColor: Theme.withAlpha(Theme.surfaceText, 0.12)
                buttonSize: 42
                enabled: MediaService.canTogglePlaying
                iconColor: Theme.surfaceText
                iconName: MediaService.playing ? "pause" : "play_arrow"
                iconSize: Theme.iconSize
                opacity: enabled ? 1 : Theme.opacityDisabled

                onClicked: MediaService.togglePlaying()
            }

            MaterialButton {
                buttonSize: 34
                enabled: MediaService.canGoNext
                iconColor: Theme.surfaceText
                iconName: "skip_next"
                opacity: enabled ? 1 : Theme.opacityDisabled

                onClicked: MediaService.next()
            }
        }
    }
}
