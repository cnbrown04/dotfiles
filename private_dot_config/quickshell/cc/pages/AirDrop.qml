// AirDrop receiver (AirDrop.qml -> airdropd): status, how-to, Send File…, Open Downloads.
import QtQuick
import QtQuick.Layouts
import qs
import qs.cc

CcPage {
    id: page

    title: "AirDrop"
    checked: AirDrop.on
    onToggled: AirDrop.toggle()

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        spacing: 10

        CcToggle {
            size: 36
            code: 0xF0003  // access-point
            checked: AirDrop.on
            busy: AirDrop.busy
            onClicked: AirDrop.toggle()
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            CcText { Layout.fillWidth: true; kind: "heading"; text: AirDrop.summary }
            CcText {
                Layout.fillWidth: true
                kind: "caption"
                text: AirDrop.on ? "Uses the Wi-Fi card while on" : "Receive files from iPhone and Mac"
            }
        }
    }

    CcText {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        Layout.bottomMargin: 4
        kind: AirDrop.status === "error" ? "caption" : "hint"
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        text: AirDrop.status === "error" ? AirDrop.detail
            : AirDrop.on
            ? "On the iPhone, set AirDrop to Everyone for 10 Minutes, then share to this computer. Files land in Downloads; AirDrop turns itself off a minute after the last one."
            : "Turn on, then on the iPhone set AirDrop to Everyone for 10 Minutes and share to this computer."
    }

    CcDivider {}

    CcActionRow {
        code: 0xF022A  // file-send
        label: "Send File…"
        onClicked: { page.cc.close(); AirDrop.sendFiles(); }
    }
    CcActionRow {
        code: 0xF024D  // folder-download
        label: "Open Downloads"
        onClicked: { page.cc.close(); AirDrop.openDownloads(); }
    }
}
