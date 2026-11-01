// Polkit authentication agent + dialog (replaces hyprpolkitagent).
// A centered MacTahoe-style sheet on the focused monitor over a light scrim: lock icon, title, the action's
// message, password field, Cancel / Authenticate. Wrong password shakes the sheet and clears the field.
// Blurred by the polkit-blur layer rule (ignore_alpha above the scrim's alpha, so only the sheet is blurred).
// Test with: pkexec true      Preview without polkit (e.g. in desktop-test): qs ipc call polkit preview
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Polkit
import QtQuick

Scope {
    id: root

    PolkitAgent { id: agent }

    // Fake flow with the same shape as AuthFlow, so the dialog can be looked at without a real request.
    // Any password but "wrong" succeeds.
    property bool previewing: false
    QtObject {
        id: mock
        property string message: "Authentication is needed to run `/usr/bin/true' as the super user"
        property string iconName: ""
        property var selectedIdentity: null
        property bool isResponseRequired: true
        property string inputPrompt: "Password: "
        property bool responseVisible: false
        property string supplementaryMessage: ""
        property bool supplementaryIsError: false
        property bool isCompleted: false
        signal authenticationFailed()
        function submit(value) {
            isResponseRequired = false;
            if (value === "wrong") { failTimer.start(); }
            else root.previewing = false;
        }
        function cancelAuthenticationRequest() { root.previewing = false; }
    }
    Timer {
        id: failTimer
        interval: 700
        onTriggered: { mock.isResponseRequired = true; mock.authenticationFailed(); }
    }

    IpcHandler {
        target: "polkit"
        function preview(): void {
            mock.isResponseRequired = true;
            root.previewing = !root.previewing;
        }
    }

    readonly property var flow: previewing ? mock : (agent.isActive ? agent.flow : null)

    PanelWindow {
        id: win

        readonly property var flow: root.flow
        readonly property bool open: flow !== null && !(flow.isCompleted ?? false)
        readonly property var focusedScreen: {
            const name = Hyprland.focusedMonitor?.name;
            return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
        }
        // Keep the last flow's text while the sheet fades out
        property var shown: null
        onFlowChanged: if (flow) shown = flow

        screen: focusedScreen
        visible: open || sheet.opacity > 0
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-polkit"
        WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"

        onOpenChanged: {
            if (open) {
                field.text = "";
                errorText.text = "";
                field.forceActiveFocus();
            }
        }

        function submit() {
            if (!flow || !flow.isResponseRequired) return;
            errorText.text = "";
            flow.submit(field.text);
        }
        function cancel() {
            if (flow) flow.cancelAuthenticationRequest();
        }

        Connections {
            target: win.flow
            ignoreUnknownSignals: true
            function onAuthenticationFailed() {
                errorText.text = "Incorrect password, try again.";
                field.text = "";
                shake.restart();
                field.forceActiveFocus();
            }
            function onIsResponseRequiredChanged() {
                if (win.flow.isResponseRequired) field.forceActiveFocus();
            }
        }

        // Scrim (kept under the blur rule's ignore_alpha, so the desktop behind stays sharp)
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: win.open ? 0.22 : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            // Clicking outside does nothing (like macOS); swallow it so it can't reach anything else
            MouseArea { anchors.fill: parent }
        }

        Item {
            id: sheet

            readonly property var f: win.shown
            // displayName is the passwd GECOS field ("Full Name,room,phone,..."); keep just the name
            readonly property string userName: (f?.selectedIdentity?.displayName ?? "").split(",")[0].trim() || Quickshell.env("USER") || ""
            readonly property bool busy: win.open && f !== null && !f.isResponseRequired

            width: 372
            height: column.implicitHeight + 2 * 24
            x: Math.round((win.width - width) / 2) + shakeOffset
            y: Math.round((win.height - height) / 2.4)
            property real shakeOffset: 0

            opacity: 0
            scale: 0.92
            states: State {
                name: "open"
                when: win.open
                PropertyChanges { target: sheet; opacity: 1; scale: 1 }
            }
            transitions: [
                Transition {
                    to: "open"
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; duration: 180; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "scale"; duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
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

            SequentialAnimation {
                id: shake
                loops: 1
                NumberAnimation { target: sheet; property: "shakeOffset"; to: -14; duration: 50 }
                NumberAnimation { target: sheet; property: "shakeOffset"; to: 12; duration: 70 }
                NumberAnimation { target: sheet; property: "shakeOffset"; to: -8; duration: 70 }
                NumberAnimation { target: sheet; property: "shakeOffset"; to: 5; duration: 60 }
                NumberAnimation { target: sheet; property: "shakeOffset"; to: 0; duration: 50 }
            }

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

            Column {
                id: column
                x: 24
                y: 24
                width: parent.width - 48
                spacing: 0

                // Lock badge (or the requesting action's icon if it names one)
                Item {
                    width: parent.width
                    height: 64

                    Rectangle {
                        id: badge
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 64
                        height: 64
                        radius: Theme.radius
                        color: Theme.moduleBg
                        border.width: 1
                        border.color: Theme.divider

                        IconImage {
                            id: actionIcon
                            anchors.centerIn: parent
                            implicitSize: 40
                            source: sheet.f?.iconName ? Quickshell.iconPath(sheet.f.iconName, true) : ""
                            visible: source != "" && status === Image.Ready
                        }
                        Glyph {
                            anchors.centerIn: parent
                            visible: !actionIcon.visible
                            code: 0xf023          // nf-fa-lock
                            size: 30
                            color: Theme.panelFg
                        }
                    }
                }

                Item { width: 1; height: 16 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Authentication Required"
                    color: Theme.panelFg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontTitle
                    font.bold: true
                }

                Item { width: 1; height: 8 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: sheet.f?.message ?? ""
                    color: Theme.altFg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody
                    lineHeight: 1.15
                }

                Item { width: 1; height: 18 }

                // User the password is for
                Rectangle {
                    width: parent.width
                    height: Theme.buttonHeight
                    radius: Theme.radiusSmall
                    color: Theme.fill
                    border.width: 1
                    border.color: Theme.moduleBorder

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Glyph { code: 0xf007; size: 14; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }  // nf-fa-user
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: sheet.userName
                            color: Theme.altFg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontBody
                        }
                    }
                }

                Item { width: 1; height: 8 }

                // Password
                Rectangle {
                    width: parent.width
                    height: Theme.buttonHeight
                    radius: Theme.radiusSmall
                    color: Theme.inputBg
                    border.width: 1
                    border.color: field.activeFocus ? Theme.focusRing : Theme.moduleBorder
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    opacity: sheet.busy ? 0.6 : 1

                    Glyph {
                        id: keyGlyph
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        code: 0xf084              // nf-fa-key
                        size: 14
                        color: Theme.dim
                    }

                    TextInput {
                        id: field
                        anchors.left: keyGlyph.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true
                        enabled: !sheet.busy
                        echoMode: sheet.f?.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        color: Theme.panelFg
                        selectionColor: Theme.focusRing
                        font.family: Theme.font
                        font.pixelSize: Theme.fontBody
                        Keys.onReturnPressed: win.submit()
                        Keys.onEnterPressed: win.submit()
                        Keys.onEscapePressed: win.cancel()

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: field.text === ""
                            text: {
                                const p = (sheet.f?.inputPrompt ?? "").trim().replace(/:$/, "");
                                return p || "Password";
                            }
                            color: Theme.textFaint
                            font: field.font
                        }
                    }
                }

                // Error / info from polkit or a failed attempt
                Item {
                    width: parent.width
                    height: errorText.text !== "" || (sheet.f?.supplementaryMessage ?? "") !== "" ? 30 : 12
                    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Text {
                        id: errorText
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        color: Theme.panelFg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontCaption
                    }
                    Text {
                        anchors.fill: errorText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        visible: errorText.text === ""
                        text: sheet.f?.supplementaryMessage ?? ""
                        color: sheet.f?.supplementaryIsError ? Theme.panelFg : Theme.altFg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontCaption
                    }
                }

                // Buttons
                Row {
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        width: (parent.width - parent.spacing) / 2
                        height: Theme.buttonHeight
                        radius: Theme.radiusSmall
                        color: cancelArea.pressed ? Theme.controlPressed : cancelArea.containsMouse ? Theme.controlHover : Theme.control
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.panelFg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontBody
                        }
                        MouseArea {
                            id: cancelArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: win.cancel()
                        }
                    }

                    Rectangle {
                        width: (parent.width - parent.spacing) / 2
                        height: Theme.buttonHeight
                        radius: Theme.radiusSmall
                        color: Theme.accent
                        opacity: sheet.busy ? 0.5 : okArea.pressed ? 0.8 : okArea.containsMouse ? 0.92 : 1
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                        Text {
                            anchors.centerIn: parent
                            text: sheet.busy ? "Checking…" : "Authenticate"
                            color: Theme.accentFg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontBody
                            font.bold: true
                        }
                        MouseArea {
                            id: okArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !sheet.busy
                            onClicked: win.submit()
                        }
                    }
                }
            }
        }
    }
}
