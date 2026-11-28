pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtCore

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool available: StandardPaths.findExecutable("wf-recorder").toString() !== ""
    readonly property string directory: {
        const videos = StandardPaths.writableLocation(StandardPaths.MoviesLocation);
        return decodeURIComponent(videos.toString().replace(/^file:\/\//, ""))
                + "/Screen Recordings";
    }
    readonly property bool active: startDelay.running || prepareDirectory.running
                                   || recorder.running || verifyRecording.running || stopping
    readonly property bool recording: !!recorder.processId
    property bool stopping: false
    property string outputName: ""
    property string outputPath: ""

    function start(output, delay) {
        if (!available || active || !output)
            return;

        outputName = output;
        const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss-zzz");
        outputPath = directory + "/Recording-" + stamp + ".mp4";
        startDelay.interval = delay;
        startDelay.restart();
    }

    function stop() {
        if (!recording || stopping)
            return;

        stopping = true;
        // SIGINT lets wf-recorder write the MP4 trailer before it exits.
        recorder.signal(2);
    }

    function notify(title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Lumen", title, body]);
    }

    Timer {
        id: startDelay

        onTriggered: prepareDirectory.running = true
    }

    Process {
        id: prepareDirectory

        command: ["mkdir", "-p", "--", root.directory]

        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode === 0)
                recorder.running = true;
            else
                root.notify("Recording failed", "Could not create " + root.directory);
        }
        // qmllint enable signal-handler-parameters
    }

    Process {
        id: recorder

        property string capturedError: ""

        command: ["wf-recorder", "--output", root.outputName, "--file", root.outputPath,
            "--framerate", "30", "--codec", "libx264", "--pixel-format", "yuv420p", "-p",
            "preset=veryfast"]

        onStarted: capturedError = ""

        stderr: StdioCollector {
            onStreamFinished: recorder.capturedError = text.trim()
        }

        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            root.stopping = false;
            if (exitCode === 0) {
                verifyRecording.running = true;
            } else {
                if (capturedError)
                    console.warn("Screen recording:", capturedError);
                root.notify("Recording failed", "wf-recorder exited before saving the recording.");
            }
        }
        // qmllint enable signal-handler-parameters
    }

    Process {
        id: verifyRecording

        command: ["test", "-s", root.outputPath]

        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode === 0)
                root.notify("Recording saved", root.outputPath);
            else
                root.notify("Recording failed", "No video was written.");
        }
        // qmllint enable signal-handler-parameters
    }
}
