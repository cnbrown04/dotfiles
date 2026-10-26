pragma Singleton
import Quickshell
import QtQuick

// Shell-wide toggles shared between the Control Center, bar and notifications.
Singleton {
    id: state

    property bool doNotDisturb: false   // hide non-critical notification banners
    property bool keepAwake: false      // idle inhibitor: no lock / screen-off while on

    // Quickshell 0.3.1 silently drops volume writes to device-routed nodes that report no
    // volume step (e.g. Bluetooth sinks); fixed upstream in 25da30d. Go through wpctl until
    // the packaged version has it. Writes are coalesced so dragging a slider stays cheap.
    property var pendingVolume: ({})
    function setVolume(node, v) {
        if (!node) return;
        pendingVolume[node.id] = Math.max(0, Math.min(1, v));
        volumeFlush.start();
    }
    Timer {
        id: volumeFlush
        interval: 30
        onTriggered: {
            for (const id in state.pendingVolume)
                Quickshell.execDetached(["wpctl", "set-volume", id, state.pendingVolume[id].toFixed(3)]);
            state.pendingVolume = {};
        }
    }
}
