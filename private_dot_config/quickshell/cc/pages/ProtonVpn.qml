// Proton VPN (ProtonVpn.qml, through the app's tray item): connect to the fastest server with the switch,
// or to one of the servers pinned in the app; open the app for everything else.
import QtQuick
import QtQuick.Layouts
import qs
import qs.cc

CcPage {
    id: page

    title: "Proton VPN"
    checked: ProtonVpn.connected
    switchBusy: ProtonVpn.busy
    onToggled: ProtonVpn.toggle()

    CcListRow {
        code: 0xF0565  // shield-check
        current: ProtonVpn.connected
        busy: ProtonVpn.busy
        interactive: false
        title: ProtonVpn.connected ? (ProtonVpn.server || "Connected")
             : ProtonVpn.summary === "Off" ? "Not Connected" : ProtonVpn.summary
        subtitle: ProtonVpn.connected ? "Connected"
                : ProtonVpn.orphaned ? "Restart the app to control it from here"
                : !ProtonVpn.running ? "The app isn't running; turning this on starts it"
                : !ProtonVpn.signedIn ? "Sign in from the Proton VPN app"
                : ProtonVpn.failed ? "Try again, or open the app for details"
                : "The switch connects to the fastest server"
    }

    // Servers pinned in the app's settings
    CcSection {
        visible: ProtonVpn.running && ProtonVpn.signedIn
        text: "Pinned Servers"
    }
    CcText {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        visible: ProtonVpn.running && ProtonVpn.signedIn && ProtonVpn.pinned.length === 0
        kind: "hint"
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        text: "Pin servers in the app (Settings › Pinned tray connections) to connect to them from here."
    }
    Repeater {
        model: ProtonVpn.running ? ProtonVpn.pinned : []
        delegate: CcListRow {
            required property var modelData
            code: 0xF023B  // flag
            title: modelData.text
            current: ProtonVpn.connected && ProtonVpn.server === modelData.text
            interactive: modelData.enabled
            dimmed: !modelData.enabled
            onClicked: ProtonVpn.connectTo(modelData)
        }
    }

    CcDivider {}
    CcActionRow {
        visible: ProtonVpn.orphaned
        code: 0xF0709  // restart
        label: "Restart Proton VPN"
        onClicked: ProtonVpn.restartApp()
    }
    CcActionRow {
        visible: !ProtonVpn.orphaned
        code: 0xF03CC  // open-in-new
        label: "Open Proton VPN"
        onClicked: { page.cc.close(); ProtonVpn.showApp(); }
    }
}
