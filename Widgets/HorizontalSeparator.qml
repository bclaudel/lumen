import QtQuick
import QtQuick.Layouts

import qs.Common

Rectangle {
    implicitHeight: 1
    Layout.fillWidth: true
    Layout.leftMargin: Theme.spacingM
    Layout.preferredHeight: 1
    Layout.rightMargin: Theme.spacingM
    color: Theme.withAlpha(Theme.surfaceText, 0.12)
}
