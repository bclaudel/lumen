import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

IconImage {
    id: root

    property real brightnessOverride: 0.5
    property string colorOverride: ""
    property real contrastOverride: 1

    asynchronous: true
    layer.enabled: colorOverride !== ""
    smooth: true

    Process {
        command: ["sh", "-c", ". /etc/os-release && echo $LOGO"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: () => {
                root.source = Quickshell.iconPath(this.text.trim());
            }
        }
    }
}
