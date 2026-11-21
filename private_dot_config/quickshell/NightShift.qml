pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Night Shift (warmer colors at night), backed by ~/.local/bin/nightshift + hyprsunset (~/config.md).
// The script owns the settings ($XDG_STATE_HOME/nightshift/state.json); this mirrors them, refreshing when
// that file changes (Vicinae commands, the terminal) and once a minute for scheduled changes.
// Slider and time changes preview right away and are written once they settle, since each write
// restarts hyprsunset to reload its profiles.
Singleton {
    id: ns

    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/nightshift"
    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state")
                                        + "/nightshift/state.json"

    readonly property int minK: 2500       // "More Warm" end of the slider
    readonly property int maxK: 6000       // "Less Warm" end

    property bool active: false
    property bool running: false
    property int temperature: 4000
    property bool schedule: true
    property string from: "21:00"          // 24h HH:MM
    property string to: "07:00"
    property string until: ""              // next change, HH:MM ("" = none)

    // "On until 7:00 AM", "Off until 9:00 PM", "On"
    readonly property string summary: (active ? "On" : "Off") + (until !== "" ? " until " + clock(until) : "")

    function clock(hhmm) {
        const [h, m] = hhmm.split(":").map(Number);
        return (h % 12 || 12) + ":" + String(m).padStart(2, "0") + (h < 12 ? " AM" : " PM");
    }
    function toMinutes(hhmm) { const [h, m] = hhmm.split(":").map(Number); return h * 60 + m; }
    function fromMinutes(min) {
        min = ((min % 1440) + 1440) % 1440;
        return String(Math.floor(min / 60)).padStart(2, "0") + ":" + String(min % 60).padStart(2, "0");
    }

    // Slider position 0..1 (0 = less warm) <-> Kelvin
    function warmth(k) { return Math.max(0, Math.min(1, (maxK - k) / (maxK - minK))); }
    function kelvin(w) { return Math.round((maxK - w * (maxK - minK)) / 100) * 100; }

    function run(args) {
        settle.restart();
        Quickshell.execDetached([bin, ...args]);
    }

    function toggle() { active = !active; run([active ? "on" : "off"]); }
    function setActive(on) { if (on !== active) toggle(); }
    function setSchedule(on) { schedule = on; run(["schedule", on ? "on" : "off"]); }

    function setTemperature(k) {
        temperature = Math.max(1000, Math.min(6500, k));
        if (active && running)   // live preview; the script saves it once the slider settles
            Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(temperature)]);
        settle.restart();
        tempCommit.restart();
    }
    function shiftTime(which, deltaMin) {
        ns[which] = fromMinutes(toMinutes(ns[which]) + deltaMin);
        settle.restart();
        timeCommit.restart();
    }

    Timer { id: tempCommit; interval: 600; onTriggered: ns.run(["temp", String(ns.temperature)]) }
    Timer { id: timeCommit; interval: 800; onTriggered: ns.run(["schedule", ns.from, ns.to]) }
    // Ignore status reads for a moment after a click, so the optimistic state doesn't flicker back
    Timer { id: settle; interval: 1500; onTriggered: ns.refresh() }

    function refresh() { if (!poll.running) poll.running = true; }

    Process {
        id: poll
        command: [ns.bin, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (settle.running || tempCommit.running || timeCommit.running) return;
                try {
                    const s = JSON.parse(text);
                    ns.active = s.active;
                    ns.running = s.running;
                    ns.temperature = s.temperature;
                    ns.schedule = s.schedule;
                    ns.from = s.from;
                    ns.to = s.to;
                    ns.until = s.until ?? "";
                } catch (e) {}
            }
        }
    }

    FileView {
        path: ns.stateFile
        watchChanges: true
        onFileChanged: ns.refresh()
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ns.refresh()
    }
}
