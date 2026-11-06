import QtQuick

Timer {
    id: root

    property int timeout: 7000
    property bool available: false

    signal expired

    interval: timeout
    repeat: false

    function markUpdated() {
        available = true;
        restart();
    }

    function invalidate() {
        stop();
        available = false;
    }

    onTriggered: {
        available = false;
        expired();
    }
}
