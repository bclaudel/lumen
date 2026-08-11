pragma Singleton
pragma ComponentBehavior

import QtQuick
import Quickshell

Singleton {
    id: root

    property int currentThemeIndex: 0
    property color archBlue: "#1793D1"
    property real barHeight: 40
    property real topBarWidgetHeight: 26
    property color buttonActiveBackground: secondary
    property color buttonBackground: surfaceVariant
    property color contentBackground: withAlpha(surfaceVariant, 0.1)
    property real cornerRadius: 12
    property color descriptionBackground: withAlpha(surfaceVariant, 0.5)
    property color error: "#F2B8B5"
    property color errorHover: Qt.rgba(error.r, error.g, error.b, 0.12)
    property color errorPressed: Qt.rgba(error.r, error.g, error.b, 0.9)
    property real fontSizeLarge: 16
    property real fontSizeMedium: 14
    property real fontSizeSmall: 12
    property real fontSizeXLarge: 20
    property real fontSizeXXLarge: 24
    property real iconSize: 24
    property real iconSizeLarge: 32
    property real iconSizeSmall: 16
    property color info: "#2196F3"
    property color inputBackground: withAlpha(surfaceContainer, 0.9)
    property color itemBackground: withAlpha(surfaceVariant, 0.03)
    property color modalScrimBackground: withAlpha(surfaceContainer, opacityInactive)
    property real opacityDisabled: 0.38
    property real opacityFull: 1
    property real opacityHigh: 0.87
    property real opacityInactive: 0.75
    property real opacityUnavailable: 0.6
    property color outline: getCurrentTheme().outline
    property color outlineButton: Qt.rgba(outline.r, outline.g, outline.b, 0.5)
    property color outlineHeavy: Qt.rgba(outline.r, outline.g, outline.b, 0.3)
    property color outlineLight: Qt.rgba(outline.r, outline.g, outline.b, 0.05)
    property color outlineMedium: Qt.rgba(outline.r, outline.g, outline.b, 0.08)
    property color outlineSelected: Qt.rgba(outline.r, outline.g, outline.b, 0.2)
    property color outlineStrong: Qt.rgba(outline.r, outline.g, outline.b, 0.12)
    property real panelTransparency: 0.85
    property color popupInputBackground: withAlpha(surfaceVariant, popupTransparency * 0.7)
    property real popupTransparency: 0.92
    property color primary: getCurrentTheme().primary
    property color primaryBackground: Qt.rgba(primary.r, primary.g, primary.b, 0.04)
    property color primaryContainer: getCurrentTheme().primaryContainer
    property color primaryHover: Qt.rgba(primary.r, primary.g, primary.b, 0.12)
    property color primaryHoverLight: Qt.rgba(primary.r, primary.g, primary.b, 0.08)
    property color primaryPressed: Qt.rgba(primary.r, primary.g, primary.b, 0.16)
    property color primarySelected: Qt.rgba(primary.r, primary.g, primary.b, 0.3)
    property color primaryText: getCurrentTheme().primaryText
    property color secondary: getCurrentTheme().secondary
    property color secondaryHover: Qt.rgba(secondary.r, secondary.g, secondary.b, 0.08)
    property color sectionBackground: withAlpha(surfaceVariant, popupTransparency * 0.4)
    property real spacingL: 16
    property real spacingM: 12
    property real spacingS: 8
    property real spacingXL: 24
    property real spacingXS: 4
    property color success: "#4CAF50"
    property color surface: getCurrentTheme().surface
    property color surfaceContainer: getCurrentTheme().surfaceContainer
    property color surfaceContainerHigh: getCurrentTheme().surfaceContainerHigh
    property color surfaceHover: Qt.rgba(surfaceVariant.r, surfaceVariant.g, surfaceVariant.b, 0.08)
    property color surfaceLight: Qt.rgba(surfaceVariant.r, surfaceVariant.g, surfaceVariant.b, 0.1)
    property color surfacePressed: Qt.rgba(surfaceVariant.r, surfaceVariant.g, surfaceVariant.b,
                                           0.12)
    property color surfaceSelected: Qt.rgba(surfaceVariant.r, surfaceVariant.g, surfaceVariant.b,
                                            0.15)
    property color surfaceText: getCurrentTheme().surfaceText
    property color surfaceTextAlpha: Qt.rgba(surfaceText.r, surfaceText.g, surfaceText.b, 0.3)
    property color surfaceTextHover: Qt.rgba(surfaceText.r, surfaceText.g, surfaceText.b, 0.08)
    property color surfaceTextLight: Qt.rgba(surfaceText.r, surfaceText.g, surfaceText.b, 0.06)
    property color surfaceTextMedium: Qt.rgba(surfaceText.r, surfaceText.g, surfaceText.b, 0.7)
    property color surfaceTextPressed: Qt.rgba(surfaceText.r, surfaceText.g, surfaceText.b, 0.12)
    property color surfaceVariant: getCurrentTheme().surfaceVariant
    property color surfaceVariantText: getCurrentTheme().surfaceVariantText
    property color surfaceVariantAlpha: Qt.rgba(surfaceVariant.r, surfaceVariant.g, surfaceVariant.b,
                                                0.2)
    property color tempDanger: "#ff5555"
    // Temperature-specific colors
    property color tempWarning: "#ff9933"
    property var themes: [
        {
            "name": "Blue",
            "primary": "#42a5f5",
            "primaryText": "#ffffff",
            "primaryContainer": "#1976d2",
            "secondary": "#8ab4f8",
            "surface": "#1a1c1e",
            "surfaceText": "#e3e8ef",
            "surfaceVariant": "#44464f",
            "surfaceVariantText": "#c4c7c5",
            "surfaceTint": "#8ab4f8",
            "background": "#1a1c1e",
            "backgroundText": "#e3e8ef",
            "outline": "#8e918f",
            "surfaceContainer": "#1e2023",
            "surfaceContainerHigh": "#292b2f"
        },
        {
            "name": "Deep Blue",
            "primary": "#0061a4",
            "primaryText": "#ffffff",
            "primaryContainer": "#004881",
            "secondary": "#42a5f5",
            "surface": "#1a1c1e",
            "surfaceText": "#e3e8ef",
            "surfaceVariant": "#44464f",
            "surfaceVariantText": "#c4c7c5",
            "surfaceTint": "#8ab4f8",
            "background": "#1a1c1e",
            "backgroundText": "#e3e8ef",
            "outline": "#8e918f",
            "surfaceContainer": "#1e2023",
            "surfaceContainerHigh": "#292b2f"
        },
        {
            "name": "Purple",
            "primary": "#D0BCFF",
            "primaryText": "#381E72",
            "primaryContainer": "#4F378B",
            "secondary": "#CCC2DC",
            "surface": "#10121E",
            "surfaceText": "#E6E0E9",
            "surfaceVariant": "#49454F",
            "surfaceVariantText": "#CAC4D0",
            "surfaceTint": "#D0BCFF",
            "background": "#10121E",
            "backgroundText": "#E6E0E9",
            "outline": "#938F99",
            "surfaceContainer": "#1D1B20",
            "surfaceContainerHigh": "#2B2930"
        }
    ]
    property color warning: "#FF9800"
    property color warningHover: Qt.rgba(warning.r, warning.g, warning.b, 0.12)
    property color widgetActiveBackground: withAlpha(primary, primaryPressed.a * widgetTransparency)
    property color widgetBackground: withAlpha(secondary, secondaryHover.a * widgetTransparency)
    property real widgetTransparency: 0.85

    function getContentBackgroundAlpha() {
        return popupTransparency;
    }

    function getCurrentTheme() {
        return themes[currentThemeIndex];
    }

    function getPopupBackgroundAlpha() {
        return popupTransparency;
    }

    function popupBackground() {
        return withAlpha(surfaceContainer, popupTransparency);
    }

    function topBarBackground(transparency) {
        return withAlpha(surfaceContainer, transparency);
    }

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }
}
