// AirPods (while connected): batteries, listening mode, Conversation Awareness. Data from AirPods.qml (LibrePods).
import QtQuick
import QtQuick.Layouts
import qs
import qs.cc

CcModule {
    id: mod

    property var cc
    readonly property bool available: AirPods.connected

    shown: cc.open
    padding: 10

    // Listening-mode button: circle + caption underneath
    component ModeButton: ColumnLayout {
        id: modeBtn

        property int code
        property string label
        property string mode            // LibrePods' menu text for this mode

        Layout.fillWidth: true
        Layout.preferredWidth: 1        // equal widths
        spacing: 4
        visible: AirPods.modes.some(e => e.text === mode)

        // Keyboard navigation (ControlCenter.qml)
        readonly property bool ccNav: true
        readonly property int navRadius: 12
        function navActivate() { AirPods.setMode(mode); }
        function navToggle() { AirPods.setMode(mode); }

        CcToggle {
            Layout.alignment: Qt.AlignHCenter
            size: 36
            code: modeBtn.code
            checked: AirPods.mode === modeBtn.mode
            onClicked: AirPods.setMode(modeBtn.mode)
        }
        CcText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: modeBtn.label
            color: AirPods.mode === modeBtn.mode ? Theme.panelFg : Theme.altFg
            font.pixelSize: 10
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CcToggle {
                size: 32
                interactive: false
                checked: true
                code: 0xF184F  // earbuds
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                CcText { Layout.fillWidth: true; kind: "heading"; text: AirPods.device?.name ?? "AirPods" }
                CcText {
                    Layout.fillWidth: true
                    kind: "caption"
                    function fmt(label, b) {
                        return b.level < 0 ? "" : label + " " + b.level + "%" + (b.charging ? "⚡" : "");
                    }
                    text: !AirPods.running ? "LibrePods isn't running"
                        : [fmt("L", AirPods.left), fmt("R", AirPods.right), fmt("Case", AirPods.caseBattery)]
                            .filter(s => s !== "").join("  ") || "Connected"
                }
            }
            CcIconButton {
                visible: AirPods.running
                code: 0xF01D8  // dots-horizontal
                size: 28
                glyphSize: 16
                onClicked: { mod.cc.close(); AirPods.openWindow(); }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: AirPods.modes.length > 0
            spacing: 4

            ModeButton { code: 0xF10D3; label: "Off"; mode: "Off" }                       // circle-off-outline
            ModeButton { code: 0xF02CB; label: "Noise Cancel"; mode: "Noise Cancellation" } // headphones
            ModeButton { code: 0xF07C5; label: "Transparency"; mode: "Transparency" }       // ear-hearing
            ModeButton { code: 0xF0068; label: "Adaptive"; mode: "Adaptive" }               // auto-fix
        }

        CcSwitchRow {
            Layout.leftMargin: 4
            visible: AirPods.conversation !== null
            code: 0xF05CB  // account-voice
            label: "Conversation Awareness"
            enabled: AirPods.conversation?.enabled ?? false
            checked: AirPods.conversation?.checkState === Qt.Checked
            onToggled: AirPods.toggleConversation()
        }
    }
}
