pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Common
import qs.Widgets

TopBarPopup {
    id: root

    readonly property var calendarLocale: Qt.locale()
    readonly property date today: clock.date
    property date displayedMonth: new Date(today.getFullYear(), today.getMonth(), 1, 12)
    readonly property bool showingCurrentMonth: displayedMonth.getFullYear() === today.getFullYear(
                                                    ) && displayedMonth.getMonth()
                                                === today.getMonth()

    function showToday() {
        displayedMonth = new Date(today.getFullYear(), today.getMonth(), 1, 12);
    }

    function moveMonth(offset) {
        displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + offset,
                                  1, 12);
    }

    function dateAt(index) {
        const mondayOffset = (displayedMonth.getDay() + 6) % 7;
        return new Date(displayedMonth.getFullYear(), displayedMonth.getMonth(), 1 - mondayOffset
                        + index, 12);
    }

    function isToday(date) {
        return date.getFullYear() === today.getFullYear() && date.getMonth() === today.getMonth()
                && date.getDate() === today.getDate();
    }

    onVisibleChanged: {
        if (visible)
            showToday();
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    content: Component {
        ColumnLayout {
            spacing: Theme.spacingS

            StyledText {
                Layout.fillWidth: true
                Layout.minimumHeight: 44
                Layout.leftMargin: Theme.spacingS
                Layout.rightMargin: Theme.spacingS
                font.family: SettingsData.displayFontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
                text: root.today.toLocaleDateString(root.calendarLocale, "dddd, d MMMM yyyy")
            }

            HorizontalSeparator {}

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: Theme.spacingXS

                StyledText {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacingS
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    text: root.displayedMonth.toLocaleDateString(root.calendarLocale, "MMMM yyyy")
                    wrapMode: Text.NoWrap
                }

                IconButton {
                    accessibleName: "Previous month"
                    iconName: "chevron_left"
                    onClicked: root.moveMonth(-1)
                }

                IconButton {
                    accessibleName: "Next month"
                    iconName: "chevron_right"
                    onClicked: root.moveMonth(1)
                }
            }

            Row {
                id: weekdays

                Layout.fillWidth: true
                Layout.preferredHeight: 24

                Repeater {
                    model: 7

                    StyledText {
                        required property int index

                        width: weekdays.width / 7
                        height: 24
                        color: Theme.surfaceTextMedium
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                        text: root.calendarLocale.standaloneDayName((index + 1) % 7,
                                                                    Locale.ShortFormat)
                        wrapMode: Text.NoWrap
                    }
                }
            }

            Grid {
                id: days

                Layout.fillWidth: true
                Layout.preferredHeight: 6 * 36
                columns: 7

                Repeater {
                    model: 42

                    Item {
                        id: dayCell

                        required property int index
                        readonly property date date: root.dateAt(index)
                        readonly property bool today: root.isToday(date)
                        readonly property bool inMonth: date.getMonth()
                                                        === root.displayedMonth.getMonth()

                        width: days.width / 7
                        height: 36
                        Accessible.role: Accessible.StaticText
                        Accessible.name: date.toLocaleDateString(root.calendarLocale,
                                                                 Locale.LongFormat)

                        Rectangle {
                            anchors.centerIn: parent
                            width: 32
                            height: 32
                            radius: Theme.cornerRadius
                            color: Theme.primary
                            visible: dayCell.today
                        }

                        StyledText {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            color: dayCell.today ? Theme.primaryText : Theme.surfaceText
                            opacity: dayCell.today || dayCell.inMonth ? Theme.opacityFull :
                                                                        Theme.opacityDisabled
                            font.weight: dayCell.today ? Font.DemiBold : Font.Normal
                            text: dayCell.date.getDate()
                        }
                    }
                }
            }

            IconButton {
                Layout.alignment: Qt.AlignHCenter
                accessibleName: "Return to current month"
                buttonWidth: 84
                circular: false
                enabled: !root.showingCurrentMonth

                contentItem: StyledText {
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.primary
                    opacity: root.showingCurrentMonth ? Theme.opacityDisabled : Theme.opacityFull
                    text: "Today"
                }

                onClicked: root.showToday()
            }
        }
    }
}
