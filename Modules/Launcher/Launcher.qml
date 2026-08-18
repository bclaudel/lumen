pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

import qs.Common
import qs.Services
import qs.Widgets

Modal {
    id: root

    property Component spotlightContent

    function show(screen) {
        root.open(screen);
    }

    function hide() {
        root.close();
    }

    modalWidth: 550
    modalHeight: 600
    backgroundColor: Theme.withAlpha(Theme.surfaceContainer, 0.9)
    borderColor: Theme.withAlpha(Theme.outline, 0.16)
    content: spotlightContent
    onBackgroundClicked: {
        hide();
    }

    spotlightContent: Component {
        Item {
            id: splotlightKeyHandler

            property alias appLauncher: appLauncher
            property alias searchField: searchField

            anchors.fill: parent
            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Escape) {
                    root.hide();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    appLauncher.selectNext();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    appLauncher.selectPrevious();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    appLauncher.launchSelected();
                    root.hide();
                    event.accepted = true;
                }
            }

            AppLauncher {
                id: appLauncher
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                border.color: Theme.withAlpha(Theme.surfaceText, 0.05)
                border.width: 1
                color: "transparent"
                radius: root.cornerRadius - 1
            }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingXL

                visible: true

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    TextField {
                        id: searchField

                        width: parent.width
                        height: 56
                        focus: true
                        backgroundColor: Theme.popupInputBackground
                        normalBorderColor: Theme.outlineMedium
                        focusedBorderColor: Theme.primary
                        iconName: "search"
                        iconSize: Theme.iconSize
                        iconColor: Theme.surfaceVariantText
                        iconFocusedColor: Theme.primary
                        placeholderText: "Search applications"

                        Component.onCompleted: Qt.callLater(() => forceActiveFocus())

                        onTextEdited: {
                            appLauncher.searchQuery = searchField.text;
                        }
                    }
                }

                Rectangle {
                    id: resultsContainer

                    width: parent.width
                    height: parent.height - y
                    radius: Theme.cornerRadius
                    color: Theme.contentBackground
                    border.color: Theme.outlineLight
                    border.width: 1

                    ListView {
                        id: resultsList

                        property int itemHeight: 60
                        property int iconSize: 40
                        property bool showDescription: true
                        property int itemSpacing: Theme.spacingS

                        signal itemClicked(int index, var modelData)

                        function ensureVisible(index) {
                            if (index < 0 || index >= count) {
                                return;
                            }

                            var itemY = index * (itemHeight + itemSpacing);
                            var itemBottom = itemY + itemHeight;
                            if (itemY < contentY) {
                                contentY = itemY;
                            } else if (itemBottom > contentY + height) {
                                contentY = itemBottom - height;
                            }
                        }

                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        model: splotlightKeyHandler.appLauncher.model
                        currentIndex: appLauncher.selectedIndex
                        clip: true
                        spacing: Theme.spacingS

                        onCurrentIndexChanged: {
                            ensureVisible(currentIndex);
                        }
                        onItemClicked: function (index, modelData) {
                            appLauncher.launchApp(modelData);
                            root.hide();
                        }

                        delegate: Rectangle {
                            id: item

                            required property int index
                            required property var model
                            required property string name
                            required property string icon

                            width: ListView.view.width
                            height: resultsList.itemHeight
                            radius: Theme.cornerRadius
                            color: ListView.isCurrentItem ? Theme.primarySelected : "transparent"
                            border.color: ListView.isCurrentItem ? Theme.primary :
                                                                   Theme.outlineMedium
                            border.width: 1

                            StateOverlay {
                                hovered: listMouseArea.containsMouse
                                pressed: listMouseArea.pressed
                            }

                            Row {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                spacing: Theme.spacingL

                                Item {
                                    width: resultsList.iconSize
                                    height: resultsList.iconSize
                                    anchors.verticalCenter: parent.verticalCenter

                                    IconImage {
                                        id: listIconImg

                                        anchors.fill: parent
                                        source: item.icon ? Quickshell.iconPath(item.icon, "") : ""
                                        smooth: true
                                        visible: source !== "" && status === Image.Ready
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        visible: !listIconImg.visible
                                        color: Theme.contentBackground
                                        radius: Theme.cornerRadius
                                        border.color: Theme.primarySelected
                                        border.width: 1

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: (item.name && item.name.length > 0) ? item.name.charAt(
                                                                                            0).toUpperCase(
                                                                                            ) : "?"
                                            font.pixelSize: resultsList.iconSize * 0.4
                                            font.weight: Font.Bold
                                            color: Theme.primary
                                        }
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - resultsList.iconSize - Theme.spacingL
                                    spacing: Theme.spacingXS

                                    StyledText {
                                        width: parent.width
                                        text: item.name || ""
                                        color: Theme.surfaceText
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        id: descriptionText

                                        width: parent.width
                                        text: item.model.comment || ""
                                        color: Theme.surfaceVariantText
                                        font.pixelSize: Theme.fontSizeMedium
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        visible: resultsList.showDescription && item.model.comment
                                                 !== ""
                                    }
                                }
                            }

                            MouseArea {
                                id: listMouseArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        resultsList.itemClicked(item.index, item.model);
                                    }
                                }
                            }

                            StyledToolTip {
                                text: item.model.comment || ""
                                visible: listMouseArea.containsMouse && descriptionText.truncated
                                width: 420
                            }
                        }
                    }
                }
            }
        }
    }

    GlobalShortcut {
        description: "Open the launcher modal"
        name: "openLauncherModal"

        onPressed: {
            root.show(ScreenService.focusedScreen);
        }
    }
}
