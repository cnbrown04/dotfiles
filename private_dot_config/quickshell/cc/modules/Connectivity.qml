// Wi-Fi / Bluetooth / AirDrop / Ethernet rows, with the Keep Awake and Night Shift tiles beside them.
import QtQuick
import QtQuick.Layouts
import qs
import qs.cc

RowLayout {
    id: mod

    property var cc
    property int delay: 0

    spacing: 10

    CcRowGroup {
        Layout.fillWidth: true
        Layout.fillHeight: true
        cc: mod.cc
        delay: mod.delay
        rows: ["Wifi", "Bluetooth", "AirDrop", "Ethernet"]
    }

    ColumnLayout {
        Layout.preferredWidth: 152
        Layout.maximumWidth: 152
        Layout.fillHeight: true
        spacing: 10

        CcTile {
            cc: mod.cc
            delay: mod.delay + 70
            code: 0xF0176  // coffee
            label: "Keep Awake"
            checked: ShellState.keepAwake
            onToggled: ShellState.keepAwake = !ShellState.keepAwake
        }
        CcTile {
            cc: mod.cc
            delay: mod.delay + 85
            code: 0xF0F65  // moon-waning-crescent
            label: "Night Shift"
            checked: NightShift.active
            page: "NightShift"
            onToggled: NightShift.toggle()
        }
    }
}
