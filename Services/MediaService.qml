pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property MprisPlayer activePlayer: null

    readonly property bool available: activePlayer !== null
    readonly property bool canGoNext: activePlayer?.canGoNext ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property bool canTogglePlaying: activePlayer?.canTogglePlaying ?? false
    readonly property bool playing: activePlayer?.isPlaying ?? false
    readonly property string artist: activePlayer?.trackArtist || activePlayer?.identity || ""
    readonly property string artworkUrl: activePlayer?.trackArtUrl || ""
    readonly property string title: activePlayer?.trackTitle || (available ? "Unknown Track" :
                                                                             "Not Playing")

    function next() {
        if (canGoNext)
            activePlayer.next();
    }

    function previous() {
        if (canGoPrevious)
            activePlayer.previous();
    }

    function resolveActivePlayer() {
        const players = Mpris.players.values;
        const playingPlayer = players.find(player => player.isPlaying);

        if (playingPlayer) {
            activePlayer = playingPlayer;
        } else if (!activePlayer || !players.includes(activePlayer)) {
            activePlayer = players.find(player => player.canControl) ?? null;
        }
    }

    function togglePlaying() {
        if (canTogglePlaying)
            activePlayer.togglePlaying();
    }

    Component.onCompleted: resolveActivePlayer()

    Connections {
        function onValuesChanged() {
            root.resolveActivePlayer();
        }

        target: Mpris.players
    }

    Instantiator {
        model: Mpris.players

        delegate: Connections {
            required property MprisPlayer modelData

            function onIsPlayingChanged() {
                root.resolveActivePlayer();
            }

            target: modelData
        }
    }
}
