pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick
import qs

// Shared Control Center state and helpers, so rows, modules and pages don't each look things up.
Singleton {
    id: util

    // Audio
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    // Network
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var wifiNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null

    // AirDrop's exclusive mode stops NetworkManager while it runs, so every device above goes away. These keep the
    // Wi-Fi and Ethernet rows in place (Wi-Fi as "Used by AirDrop") instead of the row group collapsing.
    readonly property bool netPaused: wifiDevice === null && AirDrop.on
    property bool hadWired: false
    property bool wiredLink: false
    onWiredDeviceChanged: if (wiredDevice) hadWired = true
    Binding {
        when: util.wiredDevice !== null
        target: util
        property: "wiredLink"
        value: util.wiredDevice?.hasLink ?? false
        restoreMode: Binding.RestoreNone
    }

    // Bluetooth
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter?.enabled ?? false
    readonly property var btConnected: adapter?.devices.values.filter(d => d.connected) ?? []

    // Media: the playing player, else the first one
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function wifiGlyph(strength) {
        const s = strength > 1 ? strength / 100 : strength;
        return s > 0.75 ? 0xF0928 : s > 0.5 ? 0xF0925 : s > 0.25 ? 0xF0922 : 0xF091F;
    }

    function btGlyph(icon) {
        if (/headset|headphone/.test(icon)) return 0xF02CB;
        if (/audio|speaker/.test(icon)) return 0xF04C3;
        if (/keyboard/.test(icon)) return 0xF030C;
        if (/mouse|tablet/.test(icon)) return 0xF037D;
        if (/gaming|joystick/.test(icon)) return 0xF0296;
        if (/phone/.test(icon)) return 0xF011C;
        if (/computer/.test(icon)) return 0xF0322;
        return 0xF00AF;
    }

    function percent(v) { return Math.round(v <= 1 ? v * 100 : v) + "%"; }

    // Keyboard navigation: the selected control (focus ring), null when nothing is. One panel is open at a time,
    // so one selection serves every monitor's Control Center.
    property var navItem: null

    function copy(text) { Quickshell.execDetached(["wl-copy", "--", text]); }
}
