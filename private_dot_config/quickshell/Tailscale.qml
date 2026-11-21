pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Tailscale state and controls for the Control Center (cc/rows/Tailscale.qml, pages/Tailscale.qml).
// State: `tailscale status --json` + `tailscale debug prefs`, every 3 s while a Control Center is open
// (`watching`), else every 30 s. Actions: the tailscale CLI. Changing settings as a normal user needs the
// operator set once:  sudo tailscale set --operator=$USER   (until then `needsOperator` is true after a try).
Singleton {
    id: ts

    property bool watching: false

    property bool installed: true
    property string backend: ""            // Running | Stopped | NeedsLogin | Starting | NoState
    readonly property bool up: backend === "Running"
    property bool busy: false              // an action is running
    property string error: ""              // last action's error, "" if it worked
    readonly property bool needsOperator: /access denied|operator/i.test(error)

    property string hostName: ""
    property string ip: ""
    property string tailnet: ""
    property string dnsSuffix: ""
    // { name, dnsName, ip, os, online, exitNodeOption, exitNode }
    property var peers: []
    readonly property var exitNodes: peers.filter(p => p.exitNodeOption)
    readonly property var exitNode: peers.find(p => p.exitNode) ?? null
    property bool acceptRoutes: false
    property bool acceptDns: false

    readonly property string summary: !installed ? "Not Installed"
        : busy ? (up ? "Disconnecting…" : "Connecting…")
        : backend === "NeedsLogin" ? "Needs Login"
        : !up ? "Off"
        : exitNode ? "Exit Node: " + exitNode.name
        : tailnet || "Connected"

    function toggle() { run(up ? ["down"] : ["up"]); }
    function setExitNode(peer) { run(["set", "--exit-node=" + (peer ? peer.ip : "")]); }
    function setAcceptRoutes(on) { acceptRoutes = on; run(["set", "--accept-routes=" + on]); }
    function setAcceptDns(on) { acceptDns = on; run(["set", "--accept-dns=" + on]); }

    function run(args) {
        if (action.running) return;
        busy = true;
        error = "";
        action.command = ["tailscale", ...args];
        action.running = true;
    }

    function refresh() { if (!poll.running) poll.running = true; }
    onWatchingChanged: if (watching) refresh()

    Process {
        id: action
        stderr: StdioCollector { id: actionErr }
        onExited: code => {
            ts.busy = false;
            ts.error = code === 0 ? "" : (actionErr.text.trim().split("\n")[0] || "tailscale exited with " + code);
            ts.refresh();
        }
    }

    Process {
        id: poll
        command: ["sh", "-c", "command -v tailscale >/dev/null || exit 127; tailscale status --json; printf '\\036'; tailscale debug prefs"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [statusText, prefsText] = text.split("\x1e");
                try {
                    const s = JSON.parse(statusText);
                    ts.backend = s.BackendState ?? "";
                    ts.hostName = s.Self?.HostName ?? "";
                    ts.ip = s.Self?.TailscaleIPs?.[0] ?? "";
                    ts.tailnet = s.CurrentTailnet?.Name ?? "";
                    ts.dnsSuffix = s.MagicDNSSuffix ?? "";
                    const suffix = "." + ts.dnsSuffix + ".";
                    ts.peers = Object.values(s.Peer ?? {}).map(p => ({
                        name: (p.DNSName ?? "").endsWith(suffix) ? p.DNSName.slice(0, -suffix.length) : p.HostName,
                        dnsName: (p.DNSName ?? "").replace(/\.$/, ""),
                        ip: p.TailscaleIPs?.[0] ?? "",
                        os: p.OS ?? "",
                        online: p.Online ?? false,
                        exitNodeOption: p.ExitNodeOption ?? false,
                        exitNode: p.ExitNode ?? false,
                    })).sort((a, b) => (b.online - a.online) || a.name.localeCompare(b.name));
                } catch (e) {
                    ts.backend = "";
                }
                try {
                    const p = JSON.parse(prefsText);
                    if (!ts.busy) {
                        ts.acceptRoutes = p.RouteAll ?? false;
                        ts.acceptDns = p.CorpDNS ?? false;
                    }
                } catch (e) {}
            }
        }
        onExited: code => ts.installed = code !== 127
    }

    Timer {
        interval: ts.watching ? 3000 : 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ts.refresh()
    }
}
