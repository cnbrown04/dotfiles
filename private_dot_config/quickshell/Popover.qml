// Drop-down panel under a bar pill, shared by the Control Center, calendar and workspace overview.
// Same look as the notification banners (MacTahoe popover: #242424 at Theme.panelOpacity, black rim + faint white inner rim),
// blurred by the popover-blur layer rule. Springs open from the pill's corner (scale + drop + fade) and
// closes on Esc, a click outside, or `open = false`. Put content inside; size it with panelWidth/panelHeight.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win

    required property var bar
    property bool open: false
    property string align: "right"          // under the left, center or right pill
    property int panelWidth: 344
    property int panelHeight: 200
    property int panelRadius: Theme.panelRadius
    // Called on Esc before closing; return true if it handled the key (e.g. went back a page)
    property var backAction: null
    signal closeRequested()

    default property alias content: contentArea.data

    readonly property int edge: 8              // gap to the screen edge, matches the pills' margins

    screen: bar.screen
    visible: open || panel.opacity > 0
    anchors {
        top: true
        left: align === "left"
        right: align === "right"
    }
    margins.top: Theme.barHeight - 6
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popover"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitWidth: panelWidth + 2 * (edge + 16)
    // Fixed height (the mask makes the empty part click-through), so panel height animations don't resize the surface
    implicitHeight: screen.height - Theme.barHeight
    color: "transparent"
    // Only the panel takes input; the transparent rest of the window clicks through
    mask: Region { item: panel }

    HyprlandFocusGrab {
        windows: [win, win.bar]
        active: win.open
        onCleared: win.closeRequested()
    }

    Item {
        id: panel

        x: win.align === "left" ? win.edge
         : win.align === "right" ? win.width - width - win.edge
         : Math.round((win.width - width) / 2)
        y: 8
        width: win.panelWidth
        height: win.panelHeight
        // e.g. the workspace overview gaining a card
        Behavior on width { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }
        focus: true
        transformOrigin: win.align === "left" ? Item.TopLeft : win.align === "right" ? Item.TopRight : Item.Top
        opacity: 0
        scale: 0.88
        transform: Translate { id: lift; y: -16 }

        Keys.onEscapePressed: {
            if (!(win.backAction && win.backAction()))
                win.closeRequested();
        }

        states: State {
            name: "open"
            when: win.open
            PropertyChanges { target: panel; opacity: 1; scale: 1 }
            PropertyChanges { target: lift; y: 0 }
        }
        transitions: [
            Transition {
                to: "open"
                ParallelAnimation {
                    NumberAnimation { target: panel; property: "opacity"; duration: 180; easing.type: Easing.OutCubic }
                    NumberAnimation { target: panel; property: "scale"; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                    NumberAnimation { target: lift; property: "y"; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                }
            },
            Transition {
                from: "open"
                ParallelAnimation {
                    NumberAnimation { target: panel; property: "opacity"; duration: 170; easing.type: Easing.InCubic }
                    NumberAnimation { target: panel; property: "scale"; duration: 200; easing.type: Easing.InCubic }
                    NumberAnimation { target: lift; property: "y"; duration: 200; easing.type: Easing.InCubic }
                }
            }
        ]

        // Shadow
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: -6
            radius: win.panelRadius
            color: Theme.shadow
        }

        Rectangle {
            anchors.fill: parent
            radius: win.panelRadius
            color: Theme.popoverBg
            border.width: 1
            border.color: Theme.popoverBorder

            // Faint inner rim, like glass
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: win.panelRadius - 1
                color: "transparent"
                border.width: 1
                border.color: Theme.popoverRim
            }
        }

        Item {
            id: contentArea
            anchors.fill: parent
        }
    }
}
