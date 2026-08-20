pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string applyingProfile: ""
    property string applyError: ""
    property string currentProfile: ""
    property string currentProfileError: ""
    readonly property string errorText: applyError || profileListError || currentProfileError
    readonly property bool loading: profileListQuery.running || currentProfileQuery.running
    property bool monitoring: false
    property string profileListError: ""
    property var profiles: []

    function formatError(message, fallback) {
        const firstLine = message.trim().split("\n")[0] ?? "";
        return firstLine || fallback;
    }

    function openSettings() {
        Quickshell.execDetached(["lact", "gui"]);
    }

    function refresh() {
        refreshProfiles();
        refreshCurrentProfile();
    }

    function refreshCurrentProfile() {
        if (!currentProfileQuery.running && applyingProfile === "")
            currentProfileQuery.running = true;
    }

    function refreshProfiles() {
        if (!profileListQuery.running && applyingProfile === "")
            profileListQuery.running = true;
    }

    function setProfile(profileName) {
        if (!profileName || applyingProfile !== "" || profileName === currentProfile)
            return;

        applyError = "";
        applyingProfile = profileName;
        profileApplyProcess.capturedError = "";
        profileApplyProcess.command = ["lact", "cli", "profile", "set", profileName];
        profileApplyProcess.running = true;
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.monitoring

        onTriggered: root.refreshCurrentProfile()
    }

    Process {
        id: profileListQuery

        property var parsedProfiles: []
        property string capturedError: ""

        command: ["lact", "cli", "profile", "list"]
        running: false

        stderr: StdioCollector {
            onStreamFinished: profileListQuery.capturedError = text
        }

        stdout: StdioCollector {
            onStreamFinished: {
                profileListQuery.parsedProfiles = text.split("\n").map(profile => profile.trim()).filter(
                    profile => profile !== "");
            }
        }

        onStarted: {
            capturedError = "";
            parsedProfiles = [];
        }

        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode === 0) {
                root.profiles = parsedProfiles;
                root.profileListError = "";
            } else {
                root.profileListError = root.formatError(capturedError,
                                                         "Could not load GPU profiles");
            }
        }
        // qmllint enable signal-handler-parameters
    }

    Process {
        id: currentProfileQuery

        property string capturedError: ""
        property string parsedProfile: ""

        command: ["lact", "cli", "profile", "get"]
        running: false

        stderr: StdioCollector {
            onStreamFinished: currentProfileQuery.capturedError = text
        }

        stdout: StdioCollector {
            onStreamFinished: currentProfileQuery.parsedProfile = text.trim()
        }

        onStarted: {
            capturedError = "";
            parsedProfile = "";
        }

        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode === 0 && parsedProfile !== "") {
                root.currentProfile = parsedProfile;
                root.currentProfileError = "";
            } else if (exitCode !== 0) {
                root.currentProfileError = root.formatError(capturedError,
                                                            "Could not read the active GPU profile");
            }
        }
        // qmllint enable signal-handler-parameters
    }

    Process {
        id: profileApplyProcess

        property string capturedError: ""

        running: false

        stderr: StdioCollector {
            onStreamFinished: profileApplyProcess.capturedError = text
        }

        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            const requestedProfile = root.applyingProfile;
            root.applyingProfile = "";
            if (exitCode === 0) {
                root.currentProfile = requestedProfile;
                root.applyError = "";
                Qt.callLater(() => root.refresh());
            } else {
                root.applyError = root.formatError(capturedError, "Could not apply "
                                                   + requestedProfile);
            }
        }
        // qmllint enable signal-handler-parameters
    }
}
