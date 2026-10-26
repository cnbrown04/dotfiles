pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray
import QtQuick

// AirPods state and controls, read from LibrePods' tray item (~/config.md 1.21). LibrePods publishes the
// batteries in its tooltip ("L: 80% R: 75%⚡ C: -") and the controls in its DBusMenu (listening-mode
// radio group, "Conversation Detection" checkbox), so no extra IPC is needed.
Singleton {
    id: pods

    readonly property var tray: SystemTray.items.values.find(i => i.id === "librepods") ?? null
    readonly property var device: Bluetooth.defaultAdapter?.devices.values
        .find(d => d.connected && /airpods/i.test(d.name)) ?? null
    readonly property bool connected: device !== null
    readonly property bool running: tray !== null

    // Batteries: { level: 0-100 or -1, charging: bool }, level -1 = unknown or not in the case/ear
    function battery(label) {
        const m = (tray?.tooltipDescription ?? "").match(new RegExp(label + ": (\\d+)%(⚡)?"));
        return m ? { level: parseInt(m[1]), charging: m[2] !== undefined } : { level: -1, charging: false };
    }
    readonly property var left: battery("L")
    readonly property var right: battery("R")
    readonly property var caseBattery: battery("C")

    QsMenuOpener { id: menu; menu: pods.tray?.menu ?? null }
    readonly property var entries: menu.children.values
    readonly property var modes: entries.filter(e => e.buttonType === QsMenuButtonType.RadioButton)
    readonly property string mode: modes.find(e => e.checkState === Qt.Checked)?.text ?? ""
    readonly property var conversation: entries.find(e => e.text === "Conversation Detection") ?? null

    function setMode(text) { modes.find(e => e.text === text)?.triggered(); }
    function toggleConversation() { if (conversation?.enabled) conversation.triggered(); }
    function openWindow() { entries.find(e => e.text === "Open Window")?.triggered(); }
}
