// Keyboard shortcuts cheat sheet (⌥/ or `qs ipc call cheatsheet toggle`).
// Reads the live bind table from `hyprctl binds -j` every time it opens (and again if Hyprland reloads while
// it's open), so it always matches hyprland.lua. Binds are grouped by their description, written as
// "Group: Name" (`hl.bind(keys, action, { description = "Windows: Close window" })`); binds with the same
// description share a row (⌥ 1–0, ⌥ ← → ↑ ↓). A bind without a description still shows up, under "Other",
// and the header counts them, so a forgotten description is easy to spot.
// Same glass sheet as the polkit dialog (6 px corners, no shadow, 22% scrim, blurred by the cheatsheet-blur rule).
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root

    property bool open: false
    property var groups: []          // [{ name, rows: [{ desc, combos: [[chip, ...], ...] }] }]
    property int undescribed: 0

    // Preferred group order; groups not listed here follow in the order they appear in hyprland.lua
    readonly property var order: ["Apps", "Windows", "Focus", "Workspaces", "Screenshots", "Media", "Session", "Shell"]

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.open = !root.open; }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }

    onOpenChanged: if (open) reader.running = true

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (root.open && event.name === "configreloaded") reader.running = true;
        }
    }

    Process {
        id: reader
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.build(JSON.parse(text)); }
                catch (e) { console.warn("cheatsheet: couldn't read hyprctl binds:", e); }
            }
        }
    }

    function modChips(mask) {
        // macOS order: ⌃ ⌥ ⇧ ⌘
        const out = [];
        if (mask & 4) out.push("⌃");
        if (mask & 8) out.push("⌥");
        if (mask & 1) out.push("⇧");
        if (mask & 64) out.push("⌘");
        return out;
    }

    function keyLabel(k) {
        const names = {
            left: "←", right: "→", up: "↑", down: "↓",
            SPACE: "Space", space: "Space", RETURN: "Return", Return: "Return", ESCAPE: "Esc", Escape: "Esc",
            TAB: "Tab", Tab: "Tab", BACKSPACE: "⌫", BackSpace: "⌫", DELETE: "⌦", Delete: "⌦",
            slash: "/", backslash: "\\", comma: ",", period: ".", minus: "-", equal: "=", grave: "`",
            semicolon: ";", apostrophe: "'", bracketleft: "[", bracketright: "]",
            Print: "PrtSc",
            mouse_down: "Scroll", mouse_up: "Scroll", "mouse:272": "Left drag", "mouse:273": "Right drag",
            "mouse:274": "Middle click",
            XF86AudioRaiseVolume: "Vol +", XF86AudioLowerVolume: "Vol −", XF86AudioMute: "Mute",
            XF86AudioMicMute: "Mic Mute", XF86AudioNext: "Next", XF86AudioPrev: "Prev",
            XF86AudioPlay: "Play/Pause", XF86AudioPause: "Play/Pause",
            XF86MonBrightnessUp: "Bright +", XF86MonBrightnessDown: "Bright −"
        };
        if (names[k] !== undefined) return names[k];
        if (k.startsWith("XF86")) return k.slice(4);
        return k.length === 1 ? k.toUpperCase() : k;
    }

    // Keys of binds that share a description and modifiers → chips, with 1..9,0 collapsed to "1–0"
    function keyChips(keys) {
        let labels = [];
        for (const k of keys) {
            const l = keyLabel(k);
            if (!labels.includes(l)) labels.push(l);
        }
        const digits = labels.filter(l => /^[0-9]$/.test(l));
        if (digits.length >= 3) {
            const nums = digits.map(Number).map(n => n === 0 ? 10 : n).sort((a, b) => a - b);
            const lo = nums[0], hi = nums[nums.length - 1];
            if (hi - lo + 1 === nums.length) {
                const range = `${lo}–${hi % 10}`;
                const first = labels.indexOf(digits[0]);
                labels = labels.filter(l => !digits.includes(l));
                labels.splice(first, 0, range);
            }
        }
        return labels;
    }

    function build(binds) {
        const groupMap = new Map();      // name -> Map(desc -> Map(modmask -> [keys]))
        let missing = 0;
        for (const b of binds) {
            if (b.submap) continue;
            let group = "Other", desc = "No description";
            if (b.description) {
                const i = b.description.indexOf(": ");
                if (i > 0) { group = b.description.slice(0, i); desc = b.description.slice(i + 2); }
                else desc = b.description;
            } else {
                missing++;
                desc = "No description (" + [...modChips(b.modmask), keyLabel(b.key)].join(" ") + ")";
            }
            if (!groupMap.has(group)) groupMap.set(group, new Map());
            const rows = groupMap.get(group);
            if (!rows.has(desc)) rows.set(desc, new Map());
            const byMods = rows.get(desc);
            if (!byMods.has(b.modmask)) byMods.set(b.modmask, []);
            byMods.get(b.modmask).push(b.key);
        }

        const names = [...groupMap.keys()].sort((a, b) => {
            const ia = a === "Other" ? 1000 : (root.order.indexOf(a) + 1 || 500);
            const ib = b === "Other" ? 1000 : (root.order.indexOf(b) + 1 || 500);
            return ia - ib;
        });
        const out = [];
        for (const name of names) {
            const rows = [];
            for (const [desc, byMods] of groupMap.get(name)) {
                const combos = [];
                for (const [mask, keys] of byMods)
                    combos.push([...modChips(mask), ...keyChips(keys)]);
                rows.push({ desc: desc, combos: combos, missing: name === "Other" && desc.startsWith("No description") });
            }
            out.push({ name: name, rows: rows });
        }
        root.undescribed = missing;
        root.groups = out;
    }

    PanelWindow {
        id: win

        readonly property var focusedScreen: {
            const name = Hyprland.focusedMonitor?.name;
            return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
        }
        // Three columns, filled shortest-first so they come out about even
        readonly property var columns: {
            const cols = [[], [], []], heights = [0, 0, 0];
            for (const g of root.groups) {
                let c = 0;
                for (let i = 1; i < 3; i++) if (heights[i] < heights[c]) c = i;
                cols[c].push(g);
                heights[c] += g.rows.length + 2;
            }
            return cols;
        }

        screen: focusedScreen
        visible: root.open || sheet.opacity > 0
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-cheatsheet"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.open ? 0.22 : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            MouseArea { anchors.fill: parent; onClicked: root.open = false }
        }

        Item {
            id: sheet

            width: Math.min(1060, win.width - 96)
            height: Math.min(content.implicitHeight + 2 * 28, win.height - 120)
            x: Math.round((win.width - width) / 2)
            y: Math.round((win.height - height) / 2.2)
            focus: root.open
            Keys.onEscapePressed: root.open = false

            opacity: 0
            scale: 0.94
            states: State {
                name: "open"
                when: root.open
                PropertyChanges { target: sheet; opacity: 1; scale: 1 }
            }
            transitions: [
                Transition {
                    to: "open"
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; duration: 180; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "scale"; duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                    }
                },
                Transition {
                    from: "open"
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; duration: 160; easing.type: Easing.InCubic }
                        NumberAnimation { property: "scale"; duration: 180; easing.type: Easing.InCubic }
                    }
                }
            ]

            // Swallow clicks on the sheet so they don't close it
            MouseArea { anchors.fill: parent }

            Rectangle {
                anchors.fill: parent
                radius: Theme.windowRadius
                color: Theme.popoverBg
                border.width: 1
                border.color: Theme.popoverBorder

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Theme.windowRadius - 1
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.popoverRim
                }
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: 28
                contentHeight: content.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: content
                    width: parent.width
                    spacing: 22

                    // Header
                    Item {
                        width: parent.width
                        height: 26

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Keyboard Shortcuts"
                            color: Theme.panelFg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontTitle + 2
                            font.bold: true
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.undescribed > 0
                                ? `${root.undescribed} bind${root.undescribed === 1 ? "" : "s"} without a description`
                                : "⌘ Command   ⌥ Option   ⌃ Control   ⇧ Shift"
                            color: root.undescribed > 0 ? Theme.panelFg : Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontCaption
                        }
                    }

                    Row {
                        id: columnsRow
                        width: parent.width
                        spacing: 28

                        Repeater {
                            model: win.columns

                            delegate: Column {
                                required property var modelData
                                width: (columnsRow.width - 2 * columnsRow.spacing) / 3
                                spacing: 22

                                Repeater {
                                    model: modelData

                                    delegate: Column {
                                        id: group
                                        required property var modelData
                                        width: parent.width
                                        spacing: 4

                                        Text {
                                            text: group.modelData.name
                                            color: Theme.dim
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontCaption
                                            font.bold: true
                                            bottomPadding: 4
                                        }

                                        Repeater {
                                            model: group.modelData.rows

                                            delegate: Item {
                                                id: row
                                                required property var modelData
                                                width: group.width
                                                height: Math.max(26, descText.implicitHeight)

                                                Text {
                                                    id: descText
                                                    anchors.left: parent.left
                                                    anchors.right: chips.left
                                                    anchors.rightMargin: 10
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: row.modelData.desc
                                                    elide: Text.ElideRight
                                                    color: row.modelData.missing ? Theme.dim : Theme.fg
                                                    font.family: Theme.font
                                                    font.pixelSize: Theme.fontBody
                                                    font.italic: row.modelData.missing
                                                }

                                                Row {
                                                    id: chips
                                                    anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    spacing: 6
                                                    visible: !row.modelData.missing

                                                    Repeater {
                                                        model: row.modelData.combos

                                                        delegate: Row {
                                                            id: combo
                                                            required property var modelData
                                                            required property int index
                                                            spacing: 3

                                                            Text {
                                                                visible: combo.index > 0
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: "or"
                                                                rightPadding: 3
                                                                color: Theme.dim
                                                                font.family: Theme.font
                                                                font.pixelSize: Theme.fontCaption
                                                            }

                                                            Repeater {
                                                                model: combo.modelData

                                                                delegate: Rectangle {
                                                                    required property string modelData
                                                                    width: Math.max(22, chipText.implicitWidth + 12)
                                                                    height: 22
                                                                    radius: Theme.radiusSmall
                                                                    color: Theme.control
                                                                    border.width: 1
                                                                    border.color: Theme.moduleBorder

                                                                    Text {
                                                                        id: chipText
                                                                        anchors.centerIn: parent
                                                                        text: parent.modelData
                                                                        color: Theme.panelFg
                                                                        font.family: Theme.font
                                                                        font.pixelSize: Theme.fontCaption
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
