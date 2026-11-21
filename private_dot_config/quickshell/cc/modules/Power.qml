// Lock / Log Out / Restart / Shut Down (the last three need a second click).
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.cc

CcModule {
    id: mod

    property var cc

    shown: cc.open
    padding: 10

    RowLayout {
        width: parent.width
        spacing: 0

        CcPowerButton {
            Layout.fillWidth: true
            code: 0xF033E  // lock
            label: "Lock"
            onTriggered: { mod.cc.close(); Quickshell.execDetached(["loginctl", "lock-session"]); }
        }
        CcPowerButton {
            Layout.fillWidth: true
            code: 0xF0343  // logout
            label: "Log Out"
            confirm: true
            onTriggered: Quickshell.execDetached(["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"])
        }
        CcPowerButton {
            Layout.fillWidth: true
            code: 0xF0709  // restart
            label: "Restart"
            confirm: true
            onTriggered: Quickshell.execDetached(["systemctl", "reboot"])
        }
        CcPowerButton {
            Layout.fillWidth: true
            code: 0xF0425  // power
            label: "Shut Down"
            confirm: true
            onTriggered: Quickshell.execDetached(["systemctl", "poweroff"])
        }
    }
}
