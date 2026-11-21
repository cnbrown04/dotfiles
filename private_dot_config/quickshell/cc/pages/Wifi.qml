// Wi-Fi networks: click to join (asks for a password for new secured networks) or to disconnect.
// Scans only while this page is showing.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs
import qs.cc

CcPage {
    id: page

    title: "Wi-Fi"
    checked: Networking.wifiEnabled
    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled

    Binding {
        when: page.active && CcUtil.wifiDevice !== null
        target: CcUtil.wifiDevice
        property: "scannerEnabled"
        value: true
    }

    CcPlaceholder {
        visible: wifiList.count === 0
        text: !Networking.wifiEnabled ? "Wi-Fi is off" : "Looking for networks…"
    }

    CcList {
        id: wifiList
        model: ScriptModel {
            values: !Networking.wifiEnabled || !CcUtil.wifiDevice ? []
                : [...CcUtil.wifiDevice.networks.values]
                    .filter(n => n.name !== "")
                    .sort((a, b) => (b.connected - a.connected) || (b.known - a.known)
                                    || (b.signalStrength - a.signalStrength))
        }

        delegate: Item {
            id: net

            required property var modelData
            readonly property bool secure: modelData.security !== WifiSecurityType.Open
                                        && modelData.security !== WifiSecurityType.Owe
            property bool asking: false   // password field shown
            property bool failed: false

            // Keyboard navigation (ControlCenter.qml): Enter/Space = click, except that on a new secured network
            // Enter opens the password field with the cursor in it (Tab / ↓ / ↑ leave it, Esc goes back)
            readonly property bool ccNav: true
            readonly property int navRadius: Theme.rowRadius
            function navActivate() {
                if (!net.modelData.connected && !net.modelData.known && net.secure) {
                    net.asking = true;
                    password.forceActiveFocus();
                } else {
                    activate();
                }
            }
            function navToggle() { activate(); }
            function activate() {
                const n = net.modelData;
                if (n.connected) {
                    n.disconnect();
                } else if (n.known || !net.secure) {
                    net.failed = false;
                    n.connect();
                } else {
                    net.asking = !net.asking;
                    if (net.asking) password.forceActiveFocus();
                }
            }

            width: ListView.view.width
            height: 44 + (asking ? 46 : 0)
            clip: true
            Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

            Connections {
                target: net.modelData
                function onConnectionFailed(reason) {
                    net.failed = true;
                    if (net.secure) {
                        net.asking = true;
                        password.forceActiveFocus();
                    }
                }
                function onConnectedChanged() {
                    if (net.modelData.connected) {
                        net.failed = false;
                        net.asking = false;
                        password.text = "";
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 44
                radius: Theme.rowRadius
                color: netMouse.pressed ? Theme.rowPressed : netMouse.containsMouse ? Theme.rowHover : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: netMouse
                width: parent.width
                height: 44
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: net.activate()
            }

            RowLayout {
                x: 6
                width: parent.width - 12
                height: 44
                spacing: 10

                CcToggle {
                    size: 28
                    interactive: false
                    checked: net.modelData.connected
                    code: CcUtil.wifiGlyph(net.modelData.signalStrength)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        text: net.modelData.name
                        color: Theme.panelFg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontBody
                        font.weight: net.modelData.connected ? Font.Bold : Font.Normal
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        readonly property string status: net.modelData.stateChanging ? "Connecting…"
                            : net.modelData.connected ? "Connected"
                            : net.failed ? "Couldn't connect" : ""
                        visible: status !== ""
                        text: status
                        color: Theme.altFg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontCaption
                    }
                }
                Glyph {
                    visible: net.secure
                    Layout.rightMargin: 14
                    code: 0xF033E  // lock
                    size: 12
                    color: Theme.dim
                }
            }

            // Password entry for a new secured network
            Rectangle {
                x: 6
                y: 48
                width: parent.width - 12
                height: 36
                radius: Theme.rowRadius
                color: Theme.inputBg
                border.width: 1
                border.color: password.activeFocus ? Theme.focusRing : Theme.divider
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextInput {
                    id: password
                    anchors.left: parent.left
                    anchors.right: join.left
                    anchors.leftMargin: 12
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    color: Theme.fg
                    selectionColor: Theme.focusRing
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody
                    clip: true
                    onAccepted: join.submit()

                    Text {
                        visible: password.text === ""
                        text: "Password"
                        color: Theme.dim
                        font: password.font
                    }
                }

                CcIconButton {
                    id: join
                    anchors.right: parent.right
                    anchors.rightMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    size: 30
                    glyphSize: 16
                    code: 0xF0054  // arrow-right
                    enabledLook: password.text.length >= 8
                    function submit() {
                        if (password.text.length < 8) return;
                        net.failed = false;
                        net.modelData.connectWithPsk(password.text);
                    }
                    onClicked: submit()
                }
            }
        }
    }
}
