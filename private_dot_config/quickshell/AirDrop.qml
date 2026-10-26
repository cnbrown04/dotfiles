pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// AirDrop receiver state and switch, backed by airdrop-mt7921's airdropd (~/config.md 1.21).
// Exclusive mode: while on, AirDrop has the Wi-Fi card to itself, and the daemon switches itself off
// 60s after the last transfer (180s if nothing arrives).
Singleton {
    id: ad

    readonly property string daemon: Quickshell.env("HOME") + "/.local/bin/airdropd"

    // off | waking | idle | armed | receiving | sending | switching | unreachable | restoring | error
    property string status: "off"
    property string detail: ""
    property bool watching: false       // a panel is showing it: poll faster

    readonly property bool on: !["off", "error", "restoring"].includes(status)
    readonly property bool busy: ["waking", "switching", "restoring", "sending", "receiving"].includes(status)
    readonly property string summary: {
        switch (status) {
        case "off":         return "Off";
        case "waking":      return "Starting…";
        case "idle":
        case "armed":
        case "unreachable": return "Everyone for 10 Minutes";
        case "receiving":   return "Receiving… " + (detail || "0") + "%";
        case "sending":     return "Sending…";
        case "switching":   return "Switching Wi-Fi…";
        case "restoring":   return "Restoring Wi-Fi…";
        case "error":       return "Couldn't Start";
        default:            return status;
        }
    }

    function toggle() {
        if (on) {
            status = "off";
            launching = false;
            Quickshell.execDetached([daemon, "stop"]);
        } else {
            status = "waking";
            launching = true;
            // Detached so a Quickshell reload doesn't kill it; stderr kept so a failed start can be shown
            Quickshell.execDetached(["sh", "-c", 'mkdir -p "$XDG_RUNTIME_DIR/airdropd" && exec setsid "$0" run 2>"$XDG_RUNTIME_DIR/airdropd/launch.err"', daemon]);
        }
        settle.restart();
    }

    // Set by toggle(); if the daemon reports "off" once the click has settled, the start failed
    property bool launching: false
    Process {
        id: launchError
        command: ["sh", "-c", 'head -n 1 "$XDG_RUNTIME_DIR/airdropd/launch.err"']
        stdout: StdioCollector {
            onStreamFinished: {
                ad.status = "error";
                ad.detail = text.trim().replace(/^airdropd: /, "") || "couldn't start";
            }
        }
    }
    function sendFiles() { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/airdrop-pick-send"]); }
    function openDownloads() { Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/Downloads"]); }

    Process {
        id: poll
        command: [ad.daemon, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Keep the optimistic state from a click until the daemon has had time to write its own
                if (settle.running) return;
                try {
                    const s = JSON.parse(text);
                    if (ad.launching) {
                        ad.launching = false;
                        if ((s.state ?? "off") === "off") { launchError.running = true; return; }
                    }
                    // A shown start error stays until the next toggle
                    if (ad.status === "error" && s.state === "off") return;
                    ad.status = s.state ?? "off";
                    ad.detail = s.detail ?? "";
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: ad.watching || ad.on ? 1500 : 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!poll.running) poll.running = true
    }
    Timer { id: settle; interval: 2500 }
}
