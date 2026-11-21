pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick

// Proton VPN for the Control Center, driven through the desktop app's tray item (the `protonvpn` CLI refuses
// to run while the app is open, and the app is what puts the shield in the tray):
//   state:   the tray icon file (state-connected / state-disconnected / state-error.svg) and which menu
//            entries are enabled (Connect greyed out = connecting, Disconnect greyed out = disconnecting)
//   actions: the tray's DBusMenu entries (Connect, Disconnect, pinned servers, Show)
//   server:  NetworkManager's active connection, named "ProtonVPN <server>" by the app
// Pinned servers are set in the app (Settings > Pinned tray connections).
Singleton {
    id: pv

    property bool watching: false

    readonly property var tray: SystemTray.items.values.find(i => i.id === "proton.vpn.app.gtk") ?? null
    readonly property bool running: tray !== null
    readonly property string iconState: (String(tray?.icon ?? "").match(/state-([a-z]+)/) ?? ["", ""])[1]

    QsMenuOpener { id: menu; menu: pv.tray?.menu ?? null }
    readonly property var entries: menu.children.values
    readonly property var connectEntry: entries.find(e => e.text === "Connect") ?? null
    readonly property var disconnectEntry: entries.find(e => e.text === "Disconnect") ?? null
    readonly property var showEntry: entries.find(e => e.text === "Show" || e.text === "Hide") ?? null
    readonly property var pinned: entries.filter(e => !e.isSeparator
        && !["Connect", "Disconnect", "Show", "Hide", "Quit"].includes(e.text))

    readonly property bool connected: iconState === "connected"
    readonly property bool failed: iconState === "error"
    readonly property bool connecting: !connected && connectEntry !== null && !connectEntry.enabled
    readonly property bool disconnecting: disconnectEntry !== null && !disconnectEntry.enabled
    readonly property bool busy: connecting || disconnecting || launching
    readonly property bool signedIn: connectEntry !== null || disconnectEntry !== null

    property string server: ""             // "US#123" while connected
    property bool launching: false         // started the app to connect; connects once its tray shows up

    // The app is running but its tray icon is gone: it doesn't re-register when the tray host (Quickshell)
    // restarts, so the only fix is restarting the app (restartApp()).
    property bool appRunning: false
    readonly property bool orphaned: appRunning && !running && !launching
    readonly property string appPattern: "^/usr/bin/python3 /usr/bin/protonvpn-app"

    readonly property string summary: launching ? "Starting…"
        : orphaned ? "Not in Tray"
        : !running ? "Off"
        : connecting ? "Connecting…"
        : disconnecting ? "Disconnecting…"
        : connected ? (server || "Connected")
        : failed ? "Couldn't Connect"
        : !signedIn ? "Signed Out"
        : "Off"

    function connect() {
        if (orphaned) { restartApp(); return; }
        if (!running) { launching = true; launch(); return; }
        connectEntry?.triggered();
    }
    function disconnect() { disconnectEntry?.triggered(); }
    function toggle() { if (connected || connecting) disconnect(); else connect(); }
    function connectTo(entry) { entry.triggered(); }
    function showApp() {
        if (!running) launch(false);
        else if (showEntry?.text === "Show") showEntry.triggered();
    }
    function launch(minimized = true) {
        Quickshell.execDetached(minimized ? ["protonvpn-app", "--start-minimized"] : ["protonvpn-app"]);
    }
    // Quit the running app and start it again minimized (brings the tray icon back); connects once it's up
    function restartApp() {
        launching = true;
        Quickshell.execDetached(["sh", "-c", 'pkill -f "$0"; sleep 1.5; exec setsid protonvpn-app --start-minimized', appPattern]);
    }

    Process {
        id: appCheck
        command: ["pgrep", "-f", pv.appPattern]
        onExited: code => pv.appRunning = code === 0
    }
    Timer {
        interval: pv.watching ? 3000 : 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!appCheck.running) appCheck.running = true
    }

    // Finish a connect that had to start the app first
    onConnectEntryChanged: if (launching && connectEntry?.enabled) { launching = false; connectEntry.triggered(); }
    Timer { running: pv.launching; interval: 20000; onTriggered: pv.launching = false }

    onConnectedChanged: refreshServer()
    onWatchingChanged: if (watching) refreshServer()
    function refreshServer() {
        if (!connected) { server = ""; return; }
        if (!nm.running) nm.running = true;
    }
    Process {
        id: nm
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.split("\n").find(l => l.startsWith("ProtonVPN "));
                pv.server = line ? line.slice("ProtonVPN ".length).replace(/\\:/g, ":") : "";
            }
        }
    }
}
