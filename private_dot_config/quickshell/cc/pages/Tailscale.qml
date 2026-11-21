// Tailscale (Tailscale.qml): on/off, this device's address (click to copy), exit node, Accept Routes,
// Use Tailscale DNS, and the tailnet's devices (click one to copy its address).
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.cc

CcPage {
    id: page

    title: "Tailscale"
    checked: Tailscale.up
    switchBusy: Tailscale.busy
    onToggled: Tailscale.toggle()

    // Address just copied, shown as "Copied" on its row for a moment
    property string copied: ""
    function copy(ip) { if (!ip) return; CcUtil.copy(ip); copied = ip; copiedReset.restart(); }
    Timer { id: copiedReset; interval: 1500; onTriggered: page.copied = "" }

    function osGlyph(os) {
        if (/linux/i.test(os)) return 0xF048B;      // server
        if (/windows/i.test(os)) return 0xF05B3;    // microsoft-windows
        if (/macos|ios/i.test(os)) return 0xF0035;  // apple
        if (/android/i.test(os)) return 0xF0032;    // android
        return 0xF0322;                             // laptop
    }

    CcListRow {
        code: 0xF0582  // vpn
        current: Tailscale.up
        busy: Tailscale.busy
        interactive: Tailscale.up && Tailscale.ip !== ""
        title: Tailscale.up ? (Tailscale.hostName || "This Device") : Tailscale.summary
        subtitle: Tailscale.up ? Tailscale.ip + "  ·  " + Tailscale.tailnet
                : Tailscale.backend === "NeedsLogin" ? "Run tailscale up in a terminal to log in"
                : "Not connected to the tailnet"
        trailing: page.copied !== "" && page.copied === Tailscale.ip ? "Copied" : ""
        onClicked: page.copy(Tailscale.ip)
    }

    // Changing settings without root needs the operator set once
    ColumnLayout {
        Layout.fillWidth: true
        visible: Tailscale.error !== ""
        spacing: 2

        CcText {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            kind: "caption"
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            text: Tailscale.needsOperator
                ? "Tailscale needs permission to change settings as you. Run this once in a terminal:"
                : Tailscale.error
        }
        CcActionRow {
            visible: Tailscale.needsOperator
            code: 0xF018F  // content-copy
            label: "Copy: sudo tailscale set --operator=$USER"
            onClicked: CcUtil.copy("sudo tailscale set --operator=$USER")
        }
    }

    // Exit node
    CcSection {
        visible: Tailscale.up && Tailscale.exitNodes.length > 0
        text: "Exit Node"
    }
    CcListRow {
        visible: Tailscale.up && Tailscale.exitNodes.length > 0
        code: 0xF073A  // cancel
        title: "None"
        current: Tailscale.exitNode === null
        onClicked: Tailscale.setExitNode(null)
    }
    Repeater {
        model: Tailscale.up ? Tailscale.exitNodes : []
        delegate: CcListRow {
            required property var modelData
            code: 0xF048D  // server-network
            title: modelData.name
            subtitle: modelData.online ? "" : "Offline"
            current: modelData.exitNode
            dimmed: !modelData.online
            interactive: modelData.online
            onClicked: Tailscale.setExitNode(modelData)
        }
    }

    // Settings
    CcDivider { visible: Tailscale.up; Layout.topMargin: 2 }
    CcSwitchRow {
        visible: Tailscale.up
        code: 0xF0469  // router-wireless
        label: "Accept Routes"
        checked: Tailscale.acceptRoutes
        busy: Tailscale.busy
        onToggled: Tailscale.setAcceptRoutes(!Tailscale.acceptRoutes)
    }
    CcSwitchRow {
        visible: Tailscale.up
        code: 0xF059F  // web
        label: "Use Tailscale DNS"
        checked: Tailscale.acceptDns
        busy: Tailscale.busy
        onToggled: Tailscale.setAcceptDns(!Tailscale.acceptDns)
    }

    // Devices
    CcDivider { visible: Tailscale.up && Tailscale.peers.length > 0; Layout.topMargin: 2 }
    CcSection {
        visible: Tailscale.up && Tailscale.peers.length > 0
        text: "Devices  ·  " + Tailscale.peers.filter(p => p.online).length + " online"
    }
    CcList {
        maxHeight: 232
        Layout.bottomMargin: 2
        model: ScriptModel {
            values: Tailscale.up ? Tailscale.peers : []
            objectProp: "dnsName"
        }
        delegate: CcListRow {
            required property var modelData
            width: ListView.view.width
            code: page.osGlyph(modelData.os)
            title: modelData.name
            subtitle: modelData.online ? modelData.ip : "Offline"
            current: modelData.online
            dimmed: !modelData.online
            trailing: page.copied !== "" && page.copied === modelData.ip ? "Copied" : ""
            onClicked: page.copy(modelData.ip)
        }
    }
}
